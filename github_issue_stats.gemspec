$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'github_issue_stats'

Gem::Specification.new do |s|
  s.name          = 'github_issue_stats'
  s.version       = GitHubIssueStats::VERSION
  s.date          = '2020-05-05'
  s.summary       = 'Utility for collecting stats on number of open issues over time in GitHub repositories.'
  s.authors       = ['Ivan Zuzak']
  s.email         = 'izuzak@gmail.com'
  s.files         = ['lib/github_issue_stats.rb']
  s.executables   = ['github_issue_stats']
  s.homepage      = 'https://github.com/izuzak/github_issue_stats'
  s.license       = 'MIT'
  s.require_paths = ['lib']

  s.add_runtime_dependency('commander', '~> 4.3')
  s.add_runtime_dependency('octokit', '~> 4.0')
  s.add_runtime_dependency('text-table', '~> 1.2', '>= 1.2.4')
end
