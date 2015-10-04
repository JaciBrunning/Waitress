module Waitress
  class LESSWatcher

    @@details = {}
    @@mtimes = {}
    @@watchtime = 30
    Thread.new do
      while true
        check
        sleep @@watchtime
      end
    end

    def self.set_time time
      @@watchtime = time
    end

    def self.mtime(file)
      return 0 unless File.file?(file)
      File.mtime(file).to_i
    end

    def initialize files, &action
      files.each { |x| @@details[x] = action }
    end

    def self.check
      @@details.each do |file, action|
        m = mtime_including_imports(file)
        if (@@mtimes[file].nil?) || (m > @@mtimes[file])
          @@mtimes[file] = m
          action.call file
        end
      end
    end

    # Stolen from Guard
    def self.mtime_including_imports(file)
      mtimes = [mtime(file)]
      File.readlines(file).each do |line|
        next unless line =~ /^\s*@import ['"]([^'"]+)/

        imported = File.join(File.dirname(file), Regexp.last_match[1])

        mod_time = if imported =~ /\.le?ss$/
                     mtime(imported)
                   else
                     [mtime("#{imported}.less"), mtime("#{imported}.lss")].max
                   end
        mtimes << mod_time
      end
      mtimes.max
    end

  end
end
