module SupportInterface
  module ApplicationForms
    class WorkHistoryController < SupportInterfaceController
      before_action :build_application_form

      def edit
        @work_history_form = EditWorkHistoryForm.build_from_application(@application_form)
      end

      def update
        @work_history_form = EditWorkHistoryForm.new(choice_params)

        if @work_history_form.save(@application_form)
          flash[:success] = 'Work history updated'
          redirect_to support_interface_application_form_path(@application_form)
        else
          render :edit
        end
      end

    private

      def build_application_form
        @application_form = ApplicationForm.find(params[:application_form_id])
      end

      def choice_params
        StripWhitespace.from_hash params
          .require(:support_interface_application_forms_edit_work_history_form)
          .permit(:choice, :explanation, :audit_comment)
      end
    end
  end
end
