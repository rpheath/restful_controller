module RPH
  module RestfulController
    def self.included(base)
      base.extend ControllerMethods
    end
    
    module ControllerMethods
      def restful_controller(options = {})
        class_inheritable_accessor :model, :support_pagination
        
        self.model = options[:model] || controller_name.sub(/Controller$/, '').classify.constantize
        self.support_pagination = !!(options[:pagination])
        
        include Controller::Actions
      end
    end
    
    module Controller
      module Actions
        def index
          set_resources_to (support_pagination ? model.paginated(params[:page]) : model.all)
        end
        
        def show
          find_resource
        end
        
        def new
          set_resource_to model.new
        end
        
        def create
          set_resource_to model.new(resource_params)
          resource.save!
          flash[:notice] = "#{model.to_s} saved successfully!"
          handle_redirect!
        rescue ActiveRecord::RecordInvalid => e
          flash.now[:error] = "Error: Validations Failed! (see below)"
          render :new
        end
        
        def edit
          find_resource
        end
        
        def update
          find_resource
          resource.update_attributes!(resource_params)
          flash[:notice] = "#{model.to_s} updated successfully!"
          handle_redirect!
        rescue ActiveRecord::RecordInvalid => e
          flash.now[:error] = "Error: Validations Failed! (see below)"
          render :edit
        end
        
        def destroy
          find_resource
          resource.destroy
          flash[:notice] = "#{model.to_s} was successfully deleted"
          redirect_to :back
        end
        
      private
        def find_resource
          set_resource_to model.find(params[:id])
        end

        def resource
          instance_variable_get("@#{resource_name}")
        end
        
        def resource_name
          model.to_s.downcase.singularize
        end
        
        def resource_params
          params[model.to_s.downcase.singularize.to_sym]
        end
        
        def handle_redirect!
          redirect_to (params[:continue] ? send("new_#{resource_name}_path"): send("#{resource_name.pluralize}_path"))
        end
        
        def set_resource_to(value)
          instance_variable_set("@#{resource_name}", value)
        end

        def set_resources_to(values)
          instance_variable_set("@#{resource_name.pluralize}", values)
        end
      end
    end
  end
end