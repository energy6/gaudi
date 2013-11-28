require 'rake/dsl_definition'
require_relative 'operations.rb'

module Gaudi
  #Task Generators are modules that create the types of tasks the build system supports
  module Tasks
    def self.define_file_task task_name,dependencies
      if dependencies && !dependencies.empty?
        file task_name => dependencies
      else
        file task_name
      end
    end

    #Tasks::Build contains all task generation methods for building source code
    module Build
      include StandardPaths
      def deployment_task deployment,system_config
        deps=FileList.new
        deployment.platforms.each do |platform|
          deployment.programs(platform).each do |pgm| 
            deps<<program_task(pgm,system_config)
          end
        end
        deps<<system_config.to_path
        task deployment.name => deps
      end
      def program_task program,system_config
        Tasks.define_file_task(executable(program,system_config),program_task_dependencies(program,system_config))
      end
      def library_task component,system_config
        Tasks.define_file_task(library(component,system_config),library_task_dependencies(component,system_config))
      end
      def program_task_dependencies program,system_config
        ###TODO: this is still not granular enough, the headers are bundled all together and 
        #we cannot differentiate which source depends on which header
        deps=Rake::FileList[program.configuration.to_path]
        program.dependencies.each do |dep|
          deps+=library_task_dependencies(dep,system_config)
        end
        deps+=program.sources.map{|src| Tasks.define_file_task(object_file(src,program,system_config),object_task_dependencies(src,program,system_config))}
        deps+=program.directories
        return deps.uniq
      end
      def library_task_dependencies component,system_config
        ###TODO: here any change in a dependency's interface header will trigger a build which slows incremental builds down.
        #The solution is to parse the code and add the dependencies per file
        #this is one more file task chain (obj->headers_info->c). Zukunftsmusik!
        deps=Rake::FileList[component.configuration.to_path]
        ifaces=Rake::FileList.new
        component.dependencies.each{|dep| ifaces+=dep.interface }
        deps+=component.sources.map{|src| Tasks.define_file_task(object_file(src,component,system_config),object_task_dependencies(src,component,system_config))}
        deps+=component.directories
        return deps.uniq
      end
      def object_task_dependencies src,component,system_config
        files=[src]+component.headers
        incs=component.include_paths+component.directories
        component.dependencies.each do |dep| 
          files+=dep.interface
          incs+=dep.include_paths
        end
        files+incs
      end
    end
  end
end