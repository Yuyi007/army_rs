
desc 'merge to a git branch'
task :mergeto do |t, args|
  branch1, branch2 = args.extras
  puts "merge #{branch1} to #{branch2}"
  system("git fetch . #{branch1}:#{branch2}")
end

desc 'push to a git branch'
task :push do |t, args|
  branches = args.extras
  branches.each do |branch|
    puts "push #{branch} to origin/#{branch} "
    system("git push origin #{branch}:#{branch}")
  end
end

desc 'pull a git branch'
task :pull do |t, args|
  branches = args.extras
  branches.each do |branch|
    puts "pulling origin/#{branch} to #{branch}"
    system("git fetch origin #{branch}:#{branch}")
  end
end

namespace :gitsync do
  %w(stable).each do |branch|
    desc "sync #{branch} with master branch without leaving current branch"
    task branch do |t|
      system("rake mergeto[master,#{branch}] && rake push[#{branch}]")
    end
  end
end


desc 'short cut for gitynsc:stable'
task :gits => 'gitsync:stable'