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
        # rubocop:disable Metrics/MethodLength
        def collect_os_version
          case RbConfig::CONFIG["host_os"]
          when /darwin/
            `sw_vers -productVersion`.strip
          when /linux/
            if File.exist?("/etc/os-release")
              # Extract version from os-release file safely
              os_release = File.read("/etc/os-release")
              match = os_release.match(/VERSION="?([^"]+)"?/)
              match ? match[1] : "unknown"
            else
              "unknown"
            end
          when /mswin|mingw/
            `ver`.strip
          else
            "unknown"
          end
        rescue StandardError => e
          log_error "Failed to get OS version: #{e.message}"
          "unknown"
        end
        # rubocop:enable Metrics/MethodLength

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
        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def collect_cpu_info
          cpu_info = {
            model: "unknown",
            architecture: RbConfig::CONFIG["host_cpu"],
            cores: 1,
            speed: "unknown",
            load_average: [0.0, 0.0, 0.0]
          }

          # Try to get CPU model from /proc/cpuinfo on Linux
          if File.exist?("/proc/cpuinfo")
            cpuinfo = File.read("/proc/cpuinfo")

            # Count cores
            cpu_info[:cores] = cpuinfo.scan(/^processor\s*:/).length

            # Get model name
            model_line = cpuinfo.lines.grep(/^model name\s*:/).first
            cpu_info[:model] = model_line.split(":", 2).last.strip if model_line
          end

          # Get load average
          if File.exist?("/proc/loadavg")
            loadavg = File.read("/proc/loadavg").strip.split
            cpu_info[:load_average] = [
              loadavg[0].to_f,
              loadavg[1].to_f,
              loadavg[2].to_f
            ]
          end

          cpu_info
        rescue StandardError => e
          log_error "Failed to get CPU info: #{e.message}"
          {
            model: "unknown",
            architecture: "unknown",
            cores: 1,
            speed: "unknown",
            load_average: [0.0, 0.0, 0.0]
          }
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        # Collect memory information
        #
        # @return [Hash] memory information
        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def collect_memory_info
          mem_info = {
            total: 0,
            free: 0,
            available: 0,
            used: 0
          }

          if File.exist?("/proc/meminfo")
            mem_data = File.read("/proc/meminfo")

            # Fix safe navigation chain length issues by breaking them up
            match = mem_data.match(/MemTotal:\s+(\d+)/i)
            total = match ? match.captures.first.to_i : 0

            match = mem_data.match(/MemFree:\s+(\d+)/i)
            free = match ? match.captures.first.to_i : 0

            match = mem_data.match(/MemAvailable:\s+(\d+)/i)
            available = match ? match.captures.first.to_i : 0

            mem_info[:total] = total * 1024 # Convert KB to bytes
            mem_info[:free] = free * 1024
            mem_info[:available] = available * 1024
            mem_info[:used] = mem_info[:total] - mem_info[:free]
          else
            # For non-Linux systems, try to get memory info from platform-specific commands
            case RbConfig::CONFIG["host_os"]
            when /darwin/
              # macOS
              begin
                mem_data = `sysctl hw.memsize hw.physmem`.strip.split("\n")
                total = mem_data.grep(/hw.memsize/).first&.split(":")&.last.to_i
                mem_info[:total] = total if total&.positive?
              rescue StandardError => e
                log_error "Failed to get macOS memory info: #{e.message}"
              end
            end
          end

          mem_info
        rescue StandardError => e
          log_error "Failed to get memory info: #{e.message}"
          { total: 0, free: 0, available: 0, used: 0 }
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        # Collect disk information
        #
        # @return [Hash] disk information
        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def collect_disk_info
          disk_info = {
            total: 0,
            free: 0,
            used: 0,
            filesystems: []
          }

          # Use df command to get disk usage
          begin
            df_output = `df -k`.strip.split("\n")
            df_output.shift # Remove header line

            df_output.each do |line|
              parts = line.split(/\s+/)
              next if parts.size < 6 # Skip invalid lines

              filesystem = {
                device: parts[0],
                mount_point: parts[5],
                total: parts[1].to_i * 1024, # Convert KB to bytes
                used: parts[2].to_i * 1024,
                free: parts[3].to_i * 1024,
                usage_percent: parts[4].to_i
              }

              disk_info[:filesystems] << filesystem

              # Only count real filesystems (not special ones)
              next if filesystem[:device].start_with?("tmpfs", "devtmpfs", "none")

              disk_info[:total] += filesystem[:total]
              disk_info[:used] += filesystem[:used]
              disk_info[:free] += filesystem[:free]
            end
          rescue StandardError => e
            log_error "Failed to get disk info: #{e.message}"
          end

          disk_info
        rescue StandardError => e
          log_error "Failed to get disk info: #{e.message}"
          { total: 0, free: 0, used: 0, filesystems: [] }
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

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
        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def collect_load_info
          load_avg = [0.0, 0.0, 0.0]
          load_info = {
            "1min" => 0.0,
            "5min" => 0.0,
            "15min" => 0.0
          }

          # Try to get load average from /proc/loadavg
          if File.exist?("/proc/loadavg")
            begin
              loadavg = File.read("/proc/loadavg").strip.split
              load_avg = [loadavg[0].to_f, loadavg[1].to_f, loadavg[2].to_f]
            rescue StandardError => e
              log_error "Failed to read /proc/loadavg: #{e.message}"
            end
          else
            # Try to get load average using uptime command
            begin
              uptime = `uptime`.strip
              if uptime =~ /load average:?\s+([\d.]+),?\s+([\d.]+),?\s+([\d.]+)/
                load_avg = [::Regexp.last_match(1).to_f, ::Regexp.last_match(2).to_f,
                            ::Regexp.last_match(3).to_f]
              end
            rescue StandardError => e
              log_error "Failed to get load average from uptime: #{e.message}"
            end
          end

          load_info["1min"] = load_avg[0]
          load_info["5min"] = load_avg[1]
          load_info["15min"] = load_avg[2]
          load_info
        rescue StandardError => e
          log_error "Failed to get load info: #{e.message}"
          { "1min" => 0.0, "5min" => 0.0, "15min" => 0.0 }
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        # Collect system uptime
        #
        # @return [Hash] uptime information
        # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/AbcSize
        def collect_uptime
          uptime_seconds = 0
          uptime_info = {
            seconds: 0,
            formatted: "0 days, 0 hours, 0 minutes"
          }

          if File.exist?("/proc/uptime")
            begin
              uptime_seconds = File.read("/proc/uptime").strip.split.first.to_f
            rescue StandardError => e
              log_error "Failed to read /proc/uptime: #{e.message}"
            end
          else
            # Try to get uptime using uptime command
            begin
              uptime_output = `uptime`.strip
              if uptime_output =~ /up\s+(\d+)\s+days?,\s+(\d+):(\d+)/
                days = ::Regexp.last_match(1).to_i
                hours = ::Regexp.last_match(2).to_i
                minutes = ::Regexp.last_match(3).to_i
                uptime_seconds = (days * 86_400) + (hours * 3600) + (minutes * 60)
              elsif uptime_output =~ /up\s+(\d+):(\d+)/
                hours = ::Regexp.last_match(1).to_i
                minutes = ::Regexp.last_match(2).to_i
                uptime_seconds = (hours * 3600) + (minutes * 60)
              end
            rescue StandardError => e
              log_error "Failed to get uptime from uptime command: #{e.message}"
            end
          end

          uptime_info[:seconds] = uptime_seconds.to_i
          uptime_info[:formatted] = format_uptime(uptime_seconds)
          uptime_info
        rescue StandardError => e
          log_error "Failed to get uptime: #{e.message}"
          { seconds: 0, formatted: "0 days, 0 hours, 0 minutes" }
        end
        # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/AbcSize

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
