watch( 'lib/.*\.rb' ) { |md| system("powder restart") }
watch( 'spec/.*\.rb' ) { |md| system("bundle exec rspec spec") }
watch( 'lib/.*\.rb' ) { |md| system("bundle exec rspec spec") }
