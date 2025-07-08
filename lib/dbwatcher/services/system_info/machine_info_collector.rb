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
          when /darwin/
            `sw_vers -productVersion`.strip
          when /linux/
            if File.exist?("/etc/os-release")
              File.read("/etc/os-release").match(/VERSION="?([^"]+)"?/)&.captures&.first || "unknown"
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

        # Collect memory information
        #
        # @return [Hash] memory information
        def collect_memory_info
          mem_info = {
            total: 0,
            free: 0,
            available: 0,
            used: 0
          }

          if File.exist?("/proc/meminfo")
            mem_data = File.read("/proc/meminfo")
            total = mem_data.match(/MemTotal:\s+(\d+)/i)&.captures&.first&.to_i || 0
            free = mem_data.match(/MemFree:\s+(\d+)/i)&.captures&.first&.to_i || 0
            available = mem_data.match(/MemAvailable:\s+(\d+)/i)&.captures&.first&.to_i || 0

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
                mem_info[:total] = total if total && total > 0
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

        # Collect disk information
        #
        # @return [Hash] disk information
        def collect_disk_info
          disk_info = {
            total: 0,
            free: 0,
            available: 0,
            used: 0,
            percent_used: 0
          }

          # Try to get disk usage with df command
          begin
            df_output = `df -k /`.split("\n")[1]
            if df_output
              parts = df_output.split(/\s+/)
              if parts.size >= 6
                disk_info[:total] = parts[1].to_i * 1024 # Convert KB to bytes
                disk_info[:used] = parts[2].to_i * 1024
                disk_info[:available] = parts[3].to_i * 1024
                disk_info[:free] = disk_info[:available]
                disk_info[:percent_used] = parts[4].to_i
              end
            end
          rescue StandardError => e
            log_error "Failed to get disk info from df: #{e.message}"
          end

          disk_info
        rescue StandardError => e
          log_error "Failed to get disk info: #{e.message}"
          { total: 0, free: 0, available: 0, used: 0, percent_used: 0 }
        end

        # Collect process information
        #
        # @return [Hash] process information
        def collect_process_info
          {
            current: {
              pid: Process.pid,
              ppid: Process.ppid,
              uid: Process.uid,
              gid: Process.gid,
              start_time: Time.now
            }
          }
        rescue StandardError => e
          log_error "Failed to get process info: #{e.message}"
          { current: { pid: Process.pid } }
        end

        # Collect load average information
        #
        # @return [Hash] load average information
        def collect_load_info
          load_avg = [0.0, 0.0, 0.0]

          # Try to get load average from /proc/loadavg
          if File.exist?("/proc/loadavg")
            begin
              loadavg = File.read("/proc/loadavg").strip.split
              load_avg = [
                loadavg[0].to_f,
                loadavg[1].to_f,
                loadavg[2].to_f
              ]
            rescue StandardError => e
              log_error "Failed to get load average from /proc/loadavg: #{e.message}"
            end
          end

          {
            one_minute: load_avg[0],
            five_minutes: load_avg[1],
            fifteen_minutes: load_avg[2]
          }
        rescue StandardError => e
          log_error "Failed to get load info: #{e.message}"
          { one_minute: 0.0, five_minutes: 0.0, fifteen_minutes: 0.0 }
        end

        # Collect system uptime
        #
        # @return [Integer] uptime in seconds
        def collect_uptime
          if File.exist?("/proc/uptime")
            File.read("/proc/uptime").split.first.to_f.round
          else
            case RbConfig::CONFIG["host_os"]
            when /darwin/
              begin
                `uptime`.match(/up\s+([^,]+)/)&.captures&.first || "0"
              rescue StandardError => e
                log_error "Failed to get uptime on macOS: #{e.message}"
                0
              end
            else
              0
            end
          end
        rescue StandardError => e
          log_error "Failed to get uptime: #{e.message}"
          0
        end
      end
    end
  end
end
