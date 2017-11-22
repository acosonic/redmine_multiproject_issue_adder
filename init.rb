Redmine::Plugin.register :redmine_global_issue do
  name 'Redmine Global Issue plugin'
  author 'Bilel kedidi'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  project_module :redmine_global_issue do
    permission :create_global_issue, :global_issue => [:new, :create]

    end

  menu :top_menu, :global_issue, {:controller => 'global_issue', :action => 'new' },
       caption: :global_issue,
       :if => Proc.new {
         User.current.allowed_to_globally?(:create_global_issue, {})
       }
end
