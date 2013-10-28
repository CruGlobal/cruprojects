ActiveAdmin.register TeamMember do
  form do |f|
    f.inputs "Team Member Details" do
      f.input :name
      f.input :github_login
      f.input :rescue_time_token
      f.input :team
      f.input :leader
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit team_member: [:rescue_time_token, :github_login, :name, :team_id, :leader]
    end
  end
end
