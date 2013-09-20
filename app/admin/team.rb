ActiveAdmin.register Team do
  controller do
    def permitted_params
      params.permit team: [:name]
    end
  end
end
