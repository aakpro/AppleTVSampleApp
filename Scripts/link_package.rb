#!/usr/bin/env ruby
# Links a local Swift package (Packages/<Name>) to a target of SampleTV.xcodeproj. Idempotent.
# Usage: ruby Scripts/link_package.rb <PackageName> [TargetName=SampleTV]
require 'xcodeproj'

name   = ARGV[0] or abort('usage: link_package.rb <PackageName> [Target]')
target_name = ARGV[1] || 'SampleTV'
root   = File.expand_path('..', __dir__)
abort("Packages/#{name}/Package.swift not found") unless File.exist?(File.join(root, 'Packages', name, 'Package.swift'))

project = Xcodeproj::Project.open(File.join(root, 'SampleTV.xcodeproj'))
target  = project.targets.find { |t| t.name == target_name } or abort("target #{target_name} not found")

ref = project.root_object.package_references.find do |r|
  r.isa == 'XCLocalSwiftPackageReference' && r.relative_path == "Packages/#{name}"
end
unless ref
  ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  ref.relative_path = "Packages/#{name}"
  project.root_object.package_references << ref
end

unless target.package_product_dependencies.any? { |d| d.product_name == name }
  dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.product_name = name
  target.package_product_dependencies << dep
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = dep
  target.frameworks_build_phase.files << build_file
end

project.save
puts "Linked #{name} to #{target_name}"
