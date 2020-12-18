puts "Initialising..."
require 'rubygems'
require 'zip/zip'
require 'dir'
require 'fileutils'
require 'tempfile'

def ZipDir(directory, zipfile_name)
  Zip::ZipFile.open(zipfile_name, Zip::ZipFile::CREATE) do |zipfile|
      Dir[File.join(directory+"/**/*")].each do |file|
        zipfile.add(file.sub(directory[1..-1], ''), file)
      end
  end
end
def createDir(dir)
  Dir.mkdir(dir) unless File.exists?(dir)
  FileUtils.rm_rf Dir.glob("#{dir}/*")
end

def replaceInFile(filename, originalstring, newstring)
  # save the content of the file
  file = File.read(filename)
  # replace (globally) the search string with the new string
  new_content = file.gsub(originalstring, newstring)
  # open the file again and write the new content to it
  File.open(filename, 'w') { |line| line.puts new_content }
end

def makePage(id)
  createDir("siteBuild/"+id)
  FileUtils.copy_entry("siteBuild/index.html", "siteBuild/"+id+"/index.html")
end
createDir("packBuild")
createDir("siteBuild")
createDir("BUILD")
createDir("BUILD/packs")

puts "\nCopying base pack... (This takes a while)"
FileUtils.copy_entry("packBase/", "packBuild/pack")
puts "Building normal dark nether pack..."
ZipDir("packBuild/pack/", "packBuild/00.mcpack") # Dark nether normal mode
puts "Building normal light nether pack..."
replaceInFile('./packBuild/pack/shaders/glsl/renderchunk.fragment', "resultLighting += vec3(isHell * 0.125);", "resultLighting += vec3(isHell * 0.4);")
ZipDir("packBuild/pack/", "packBuild/01.mcpack") # Light nether normal mode
puts "Building compatable light nether pack..."
FileUtils.rm_rf("packBuild/pack/textures/")
replaceInFile('./packBuild/pack/shaders/glsl/renderchunk.fragment', "//vec4 diffuse = texture2D(TEXTURE_0, uv0 * 32.0 - vec2(1.0, 0.0));", "vec4 diffuse = texture2D(TEXTURE_0, uv0 * 32.0 - vec2(1.0, 0.0));")
ZipDir("packBuild/pack/", "packBuild/10.mcpack") # Light nether compatable mode
puts "Building compatable dark nether pack..."
replaceInFile('./packBuild/pack/shaders/glsl/renderchunk.fragment', "resultLighting += vec3(isHell * 0.4);", "resultLighting += vec3(isHell * 0.125);")
ZipDir("packBuild/pack/", "packBuild/11.mcpack") # Dark nether compatable mode
puts("Finishing pack build...")
FileUtils.rm_rf("packBuild/pack")
FileUtils.copy_entry("packBuild/", "BUILD/packs")
FileUtils.rm_rf("packBuild")

puts "\nCopying site base"
FileUtils.copy_entry("siteBase/", "BUILD")
puts "Building site..."
FileUtils.copy_entry("resources/base.html", "siteBuild/index.html")
ids = ['00','01','10','11']
ids.each { |id| makePage(id) }
puts "Finishing site build..."
FileUtils.rm("siteBuild/index.html")
FileUtils.copy_entry("siteBuild/", "BUILD")
FileUtils.rm_rf("siteBuild")
puts "\ndone."