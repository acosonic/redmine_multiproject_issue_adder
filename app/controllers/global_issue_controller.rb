class GlobalIssueController < ApplicationController
  unloadable

  helper :journals
  helper :projects
  helper :custom_fields
  helper :issue_relations
  helper :watchers
  helper :attachments
  helper :queries
  helper :issues
  include QueriesHelper
  helper :repositories
  helper :timelog

  before_action :build_new_issue_from_params, :only => [:new]

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  def new
    respond_to do |format|
      format.html { render :action => 'new', :layout => !request.xhr? }
      format.js
    end
  end

  def create
    @errors = []
    @projects = params[:issue][:project_ids].map(&:presence).compact
    first_issue = nil
    @projects.each_with_index  do |project_id, index|
      params[:issue][:project_id] = project_id
      @project = Project.find project_id
      build_new_issue_from_params
      call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
      if index.zero?
        @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
        if @issue.save
          first_issue = @issue
          call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
        else
          @errors << "#{@issue.project} => #{@issue.errors.full_messages.join(',')}"
        end
      else
        if first_issue and first_issue.attachments.present?
          @issue.attachments = first_issue.attachments.map do |attachement|
            attachement.copy(:container => @issue)
          end
        end
        # @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
        if @issue.save
          call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
        else
          @errors << "#{@issue.project} => #{@issue.errors.full_messages.join(',')}"
        end
      end


    end
    respond_to do |format|
      format.html {
        # render_attachment_warning_if_needed(@issue)
        if @errors.present?
          flash[:error] = @errors.join('<br/>')
        else
          flash[:notice] = l(:issues_created)
        end
        redirect_to new_global_issue_path
      }
    end
  end




  private
  def build_new_issue_from_params
    @issue = Issue.new

    @issue.project = @project
    if request.get?
      @issue.project ||= @issue.allowed_target_projects.first
    end
    @issue.author ||= User.current
    @issue.start_date ||= User.current.today if Setting.default_issue_start_date_to_creation_date?

    attrs = (params[:issue] || {}).deep_dup
    if action_name == 'new' && params[:was_default_status] == attrs[:status_id]
      attrs.delete(:status_id)
    end
    if action_name == 'new' && params[:form_update_triggered_by] == 'issue_project_id'
      # Discard submitted version when changing the project on the issue form
      # so we can use the default version for the new project
      attrs.delete(:fixed_version_id)
    end
    @issue.safe_attributes = attrs

    if @issue.project
      @issue.tracker ||= @issue.allowed_target_trackers.first
      if @issue.tracker.nil?
        if @issue.project.trackers.any?
          # None of the project trackers is allowed to the user
          render_error :message => l(:error_no_tracker_allowed_for_new_issue_in_project), :status => 403
        else
          # Project has no trackers
          render_error l(:error_no_tracker_in_project)
        end
        return false
      end
      if @issue.status.nil?
        render_error l(:error_no_default_issue_status)
        return false
      end
    elsif request.get?
      render_error :message => l(:error_no_projects_with_tracker_allowed_for_new_issue), :status => 403
      return false
    end

    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
  end

end
