module SupportInterface
  module ApplicationForms
    class AddressTypeController < SupportInterfaceController
      def edit
        @details = details_form
      end

      def update
        application_form.assign_attributes(address_type_params)
        @details = details_form
        if @details.save_address_type(application_form)
          redirect_to support_interface_application_form_edit_address_details_path
        else
          render :edit
        end
      end

    private

      def address_type_params
        params.require(:support_interface_application_forms_edit_address_details_form).permit(
          :address_type,
          :country,
        )
      end

      def details_form
        @details ||= EditAddressDetailsForm.build_from_application_form(application_form)
      end

      def application_form
        @application_form ||= ApplicationForm.find(params[:application_form_id])
      end
    end
  end
end
