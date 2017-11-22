Redmine::Plugin.register :redmine_multiproject_issue_adder do
  name 'Redmine Global Issue plugin'
  author 'Bilel kedidi'
  description 'This is a plugin for Redmine'
  version '1.0.0'

  project_module :redmine_multiproject_issue_adder do
    permission :create_multiproject_issue, :global_issue => [:new, :create]
  end

  menu :top_menu, :global_issue, {:controller => 'global_issue', :action => 'new' },
       caption: :global_issue,
       :if => Proc.new {
         User.current.allowed_to_globally?(:create_multiproject_issue, {})
       }
end
