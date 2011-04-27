def restart_and_spec
  system("powder restart")
  system("bundle exec rspec spec")
end

watch( 'lib/.*\.rb' ) { |md| restart_and_spec }
watch( 'views/.*') { |md| restart_and_spec }
watch( 'spec/.*\.rb' ) { |md| system("bundle exec rspec spec") }
