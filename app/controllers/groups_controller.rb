# frozen_string_literal: true

class GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group, only: [:show, :edit, :update, :destroy]

  # SECURITY: Authorization checks to prevent IDOR attacks
  # Viewers: Can only view groups (index, show)
  # Operators: Can manage groups (new, create, edit, update, destroy)
  # Admins: Full access
  before_action :require_operator!, only: [:new, :create, :edit, :update, :destroy]

  # GET /groups
  def index
    @groups = Group.includes(:servers).ordered
    @ungrouped_count = Server.ungrouped.count
  end

  # GET /groups/:id
  def show
    @servers = @group.servers.order(:hostname)
    @stats = @group.server_stats
    @recent_commands = Command.where(server_id: @group.servers.pluck(:id))
                              .order(created_at: :desc)
                              .limit(10)
  end

  # GET /groups/new
  def new
    @group = Group.new
  end

  # GET /groups/:id/edit
  def edit
  end

  # POST /groups
  def create
    @group = Group.new(group_params)

    if @group.save
      redirect_to groups_path, notice: "Group '#{@group.name}' was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /groups/:id
  def update
    if @group.update(group_params)
      redirect_to group_path(@group), notice: "Group '#{@group.name}' was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /groups/:id
  def destroy
    name = @group.name
    servers_count = @group.servers_count

    # Unassign all servers from this group
    @group.servers.update_all(group_id: nil)

    @group.destroy
    redirect_to groups_path, notice: "Group '#{name}' was deleted. #{servers_count} server(s) are now ungrouped."
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :description, :color, :slug)
  end
end
