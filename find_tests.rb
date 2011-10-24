#
# This script will take in a path, stuff it into your LOAD_PATH and
# automatically import any test modules it finds with a filename that
# is prefixed with "test_"
#

class PluginTestRunner
    def initialize(rootpath)
        @rootpath = rootpath
    end

    def _discover_tests()
        glob_path = File.join(@rootpath, "**", "test_*.rb")
        puts "Searching [#{glob_path}]"
        Dir.glob(glob_path).each do|f|
            yield f
        end
    end

    def load_tests()
        _discover_tests() do |path|
            path_parts = path.split(File::SEPARATOR).map {|x| x=="" ? File::SEPARATOR : x}
            test_module = File.join(path_parts.slice(1, path_parts.length + 1))
            test_module = test_module.sub(".rb", '')
            puts "Loading test module: #{test_module}"
            require test_module
            puts "Loaded : [#{test_module}]"
        end
    end
end

if __FILE__ == $PROGRAM_NAME
    plugin_path = 'plugin'
    runner = PluginTestRunner.new plugin_path
    $:.unshift plugin_path
    runner.load_tests()
    puts "Finished the runner!"
end

