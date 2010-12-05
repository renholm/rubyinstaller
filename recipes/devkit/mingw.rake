require 'rake'
require 'rake/clean'

namespace(:devkit) do
  namespace(:mingw) do
    package = DevKitInstaller::COMPILERS[ENV['DKVER']]
    fail '[FAIL] unable to find correct DevKit compiler version configuration' unless package

    directory package.target
    CLEAN.include(package.target)

    dt = checkpoint(:mingw, :download)
    package.files.each do |k,v|
      v.each do |f|
        #TODO handle exception when no corresponding URL defined on package
        file_source = "#{package.send(k)}/#{f}"
        file_target = "downloads/#{f}"
        download file_target => file_source

        # depend on downloads directory
        file file_target => "downloads"

        # download task needs the packages files as pre-requisites
        dt.enhance [file_target]
      end
    end
    task :download => dt

    # extract each of the packages files into the target dir
    # if archive passes 7-Zip integrity test
    et = checkpoint(:mingw, :extract) do
      dt.prerequisites.each do |f|
        fail "[FAIL] corrupt '#{f}' archive" unless seven_zip_valid?(f)
        extract(File.join(RubyInstaller::ROOT, f), package.target)
      end
    end
    task :extract => [:extract_utils, :download, package.target, et]
  end

  task :mingw => ['devkit:msys']
  task :mingw => ['devkit:mingw:download', 'devkit:mingw:extract']
end
