# frozen_string_literal: true

require "socket"
require "rbconfig"
require_relative "../../logging"

module Dbwatcher
  module Services
    module SystemInfo
      # Machine information collector service
      #
      # Collects system-level information about the machine including CPU, memory,
      # disk usage, and process information.
      #
      # @example
      #   info = SystemInfo::MachineInfoCollector.call
      #   puts info[:cpu][:model]
      #   puts info[:memory][:total]
      #   puts info[:disk][:total]
      #
      # This class is necessarily complex due to the comprehensive machine information
      # it needs to collect across different operating systems.
      # rubocop:disable Metrics/ClassLength
      class MachineInfoCollector
        include Dbwatcher::Logging

        # Class method to create instance and call
        #
        # @return [Hash] machine information
        def self.call
          new.call
        end

        def call
          log_info "#{self.class.name}: Collecting machine information"

          {
            hostname: collect_hostname,
            os: collect_os_info,
            cpu: collect_cpu_info,
            memory: collect_memory_info,
            disk: collect_disk_info,
            process: collect_process_info,
            load: collect_load_info,
            uptime: collect_uptime
          }
        rescue StandardError => e
          log_error "Machine info collection failed: #{e.message}"
          { error: e.message }
        end

        private

        # Collect hostname information
        #
        # @return [String] hostname
        def collect_hostname
          Socket.gethostname
        rescue StandardError => e
          log_error "Failed to get hostname: #{e.message}"
          "unknown"
        end

        # Collect operating system information
        #
        # @return [Hash] operating system information
        def collect_os_info
          {
            name: RbConfig::CONFIG["host_os"],
            version: collect_os_version,
            kernel: collect_kernel_version
          }
        rescue StandardError => e
          log_error "Failed to get OS info: #{e.message}"
          { name: "unknown", version: "unknown", kernel: "unknown" }
        end

        # Collect operating system version
        #
        # @return [String] operating system version
        def collect_os_version
          case RbConfig::CONFIG["host_os"]
          when /darwin/  then darwin_os_version
          when /linux/   then linux_os_version
          when /mswin|mingw/ then `ver`.strip
          else "unknown"
          end
        rescue StandardError => e
          log_error "Failed to get OS version: #{e.message}"
          "unknown"
        end

        # Read macOS product version
        #
        # @return [String] macOS version
        def darwin_os_version
          `sw_vers -productVersion`.strip
        rescue StandardError
          "unknown"
        end

        # Read Linux OS version from /etc/os-release
        #
        # @return [String] Linux version string
        def linux_os_version
          return "unknown" unless File.exist?("/etc/os-release")

          os_release = File.read("/etc/os-release")
          match = os_release.match(/VERSION="?([^"]+)"?/)
          match ? match[1] : "unknown"
        rescue StandardError
          "unknown"
        end

        # Collect kernel version
        #
        # @return [String] kernel version
        def collect_kernel_version
          `uname -r`.strip
        rescue StandardError => e
          log_error "Failed to get kernel version: #{e.message}"
          "unknown"
        end

        # Collect CPU information
        #
        # @return [Hash] CPU information
        def collect_cpu_info
          cpu_info = default_cpu_info
          enrich_cpu_info_from_proc(cpu_info)
          cpu_info[:load_average] = read_load_average_from_proc
          cpu_info
        rescue StandardError => e
          log_error "Failed to get CPU info: #{e.message}"
          default_cpu_info.merge(architecture: "unknown")
        end

        # Default CPU info hash
        #
        # @return [Hash] default CPU info
        def default_cpu_info
          {
            model: "unknown",
            architecture: RbConfig::CONFIG["host_cpu"],
            cores: 1,
            speed: "unknown",
            load_average: [0.0, 0.0, 0.0]
          }
        end

        # Enrich cpu_info hash from /proc/cpuinfo if available
        #
        # @param cpu_info [Hash] hash to mutate
        # @return [void]
        def enrich_cpu_info_from_proc(cpu_info)
          return unless File.exist?("/proc/cpuinfo")

          cpuinfo = File.read("/proc/cpuinfo")
          cpu_info[:cores] = cpuinfo.scan(/^processor\s*:/).length

          model_line = cpuinfo.lines.grep(/^model name\s*:/).first
          cpu_info[:model] = model_line.split(":", 2).last.strip if model_line
        rescue StandardError
          # Leave cpu_info unchanged
        end

        # Read load average from /proc/loadavg
        #
        # @return [Array<Float>] 1/5/15 min load averages
        def read_load_average_from_proc
          return [0.0, 0.0, 0.0] unless File.exist?("/proc/loadavg")

          parts = File.read("/proc/loadavg").strip.split
          [parts[0].to_f, parts[1].to_f, parts[2].to_f]
        rescue StandardError
          [0.0, 0.0, 0.0]
        end

        # Collect memory information
        #
        # @return [Hash] memory information
        def collect_memory_info
          if File.exist?("/proc/meminfo")
            linux_memory_info
          else
            fallback_memory_info
          end
        rescue StandardError => e
          log_error "Failed to get memory info: #{e.message}"
          { total: 0, free: 0, available: 0, used: 0 }
        end

        # Parse Linux /proc/meminfo
        #
        # @return [Hash] memory info
        def linux_memory_info
          mem_data = File.read("/proc/meminfo")
          total     = parse_meminfo_value(mem_data, "MemTotal")
          free_mem  = parse_meminfo_value(mem_data, "MemFree")
          available = parse_meminfo_value(mem_data, "MemAvailable")

          total_bytes = total * 1024
          free_bytes  = free_mem * 1024
          {
            total: total_bytes,
            free: free_bytes,
            available: available * 1024,
            used: total_bytes - free_bytes
          }
        end

        # Extract a KB value from /proc/meminfo text
        #
        # @param mem_data [String] content of /proc/meminfo
        # @param key [String] field name (e.g. "MemTotal")
        # @return [Integer] value in KB
        def parse_meminfo_value(mem_data, key)
          match = mem_data.match(/#{key}:\s+(\d+)/i)
          match ? match.captures.first.to_i : 0
        end

        # Fallback memory info for non-Linux systems
        #
        # @return [Hash] memory info
        def fallback_memory_info
          mem_info = { total: 0, free: 0, available: 0, used: 0 }
          return darwin_memory_info(mem_info) if RbConfig::CONFIG["host_os"] =~ /darwin/

          mem_info
        end

        # Attempt to read macOS memory size via sysctl
        #
        # @param mem_info [Hash] hash to populate
        # @return [Hash] memory info
        def darwin_memory_info(mem_info)
          mem_data = `sysctl hw.memsize hw.physmem`.strip.split("\n")
          total = mem_data.grep(/hw.memsize/).first&.split(":")&.last.to_i
          mem_info[:total] = total if total&.positive?
          mem_info
        rescue StandardError => e
          log_error "Failed to get macOS memory info: #{e.message}"
          mem_info
        end

        # Collect disk information
        #
        # @return [Hash] disk information
        def collect_disk_info
          disk_info = { total: 0, free: 0, used: 0, filesystems: [] }
          parse_df_output(disk_info)
          disk_info
        rescue StandardError => e
          log_error "Failed to get disk info: #{e.message}"
          { total: 0, free: 0, used: 0, filesystems: [] }
        end

        # Parse `df -k` output into disk_info hash
        #
        # @param disk_info [Hash] hash to populate
        # @return [void]
        def parse_df_output(disk_info)
          df_lines = `df -k`.strip.split("\n")
          df_lines.shift # Remove header

          df_lines.each do |line|
            filesystem = parse_df_line(line)
            next unless filesystem

            disk_info[:filesystems] << filesystem
            accumulate_disk_totals(disk_info, filesystem)
          end
        rescue StandardError => e
          log_error "Failed to get disk info: #{e.message}"
        end

        # Parse a single `df` output line into a filesystem hash
        #
        # @param line [String] single df output line
        # @return [Hash, nil] filesystem hash or nil if invalid
        def parse_df_line(line)
          parts = line.split(/\s+/)
          return nil if parts.size < 6

          {
            device: parts[0],
            mount_point: parts[5],
            total: parts[1].to_i * 1024,
            used: parts[2].to_i * 1024,
            free: parts[3].to_i * 1024,
            usage_percent: parts[4].to_i
          }
        end

        # Add real filesystem totals to the aggregate disk_info hash
        #
        # @param disk_info [Hash] aggregate hash to update
        # @param fs [Hash] single filesystem entry
        # @return [void]
        def accumulate_disk_totals(disk_info, filesystem)
          return if filesystem[:device].start_with?("tmpfs", "devtmpfs", "none")

          disk_info[:total] += filesystem[:total]
          disk_info[:used]  += filesystem[:used]
          disk_info[:free]  += filesystem[:free]
        end

        # Collect process information
        #
        # @return [Hash] process information
        def collect_process_info
          {
            pid: Process.pid,
            ppid: Process.ppid,
            uid: Process.uid,
            gid: Process.gid,
            working_directory: Dir.pwd
          }
        rescue StandardError => e
          log_error "Failed to get process info: #{e.message}"
          { pid: 0, ppid: 0, uid: 0, gid: 0, working_directory: "unknown" }
        end

        # Collect load average information
        #
        # @return [Hash] load average information
        def collect_load_info
          avg = load_average_triple
          { "1min" => avg[0], "5min" => avg[1], "15min" => avg[2] }
        rescue StandardError => e
          log_error "Failed to get load info: #{e.message}"
          { "1min" => 0.0, "5min" => 0.0, "15min" => 0.0 }
        end

        # Return [1min, 5min, 15min] load averages from /proc or uptime
        #
        # @return [Array<Float>]
        def load_average_triple
          return read_load_average_from_proc if File.exist?("/proc/loadavg")

          load_average_from_uptime
        end

        # Parse load averages from the `uptime` command output
        #
        # @return [Array<Float>]
        def load_average_from_uptime
          uptime = `uptime`.strip
          if uptime =~ /load average:?\s+([\d.]+),?\s+([\d.]+),?\s+([\d.]+)/
            [::Regexp.last_match(1).to_f, ::Regexp.last_match(2).to_f, ::Regexp.last_match(3).to_f]
          else
            [0.0, 0.0, 0.0]
          end
        rescue StandardError => e
          log_error "Failed to get load average from uptime: #{e.message}"
          [0.0, 0.0, 0.0]
        end

        # Collect system uptime
        #
        # @return [Hash] uptime information
        def collect_uptime
          seconds = read_uptime_seconds
          { seconds: seconds.to_i, formatted: format_uptime(seconds) }
        rescue StandardError => e
          log_error "Failed to get uptime: #{e.message}"
          { seconds: 0, formatted: "0 days, 0 hours, 0 minutes" }
        end

        # Read uptime in seconds from /proc or uptime command
        #
        # @return [Float] uptime in seconds
        def read_uptime_seconds
          return File.read("/proc/uptime").strip.split.first.to_f if File.exist?("/proc/uptime")

          uptime_seconds_from_command
        end

        # Parse uptime seconds from the `uptime` shell command
        #
        # @return [Float] uptime in seconds
        def uptime_seconds_from_command
          parse_uptime_output(`uptime`.strip)
        rescue StandardError => e
          log_error "Failed to get uptime from uptime command: #{e.message}"
          0
        end

        # Parse uptime output string into seconds
        #
        # @param output [String] uptime command output
        # @return [Integer] uptime in seconds
        def parse_uptime_output(output)
          if output =~ /up\s+(\d+)\s+days?,\s+(\d+):(\d+)/
            days    = ::Regexp.last_match(1).to_i
            hours   = ::Regexp.last_match(2).to_i
            minutes = ::Regexp.last_match(3).to_i
            (days * 86_400) + (hours * 3600) + (minutes * 60)
          elsif output =~ /up\s+(\d+):(\d+)/
            hours   = ::Regexp.last_match(1).to_i
            minutes = ::Regexp.last_match(2).to_i
            (hours * 3600) + (minutes * 60)
          else
            0
          end
        end

        # Format uptime seconds into a human-readable string
        #
        # @param seconds [Float] uptime in seconds
        # @return [String] formatted uptime
        def format_uptime(seconds)
          seconds = seconds.to_i
          days = seconds / 86_400
          seconds %= 86_400
          hours = seconds / 3600
          seconds %= 3600
          minutes = seconds / 60

          "#{days} days, #{hours} hours, #{minutes} minutes"
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
