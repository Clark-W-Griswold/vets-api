# frozen_string_literal: true

require 'features_helper'

RSpec.describe('hca', type: :feature) do
  def next_form_page
    wait_for_new_url('.usa-button-primary')
  end

  def start_application
    visit("#{DEFAULT_HOST}/health-care/apply/application/introduction")
    wait_for_new_url { first_with_wait('.schemaform-start-button').click }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def common_fill_hca_form(logged_in)
    # gender
    find('#root_gender').find(:option, 'Male').select_option
    find('#root_maritalStatus').find(:option, 'Never Married').select_option
    next_form_page
    # addr
    find('#root_veteranAddress_street').set('123 fake st')
    find('#root_veteranAddress_city').set('city')
    find('#root_veteranAddress_state').find(:option, 'Arizona').select_option
    find('#root_veteranAddress_postalCode').set('').set('12345')
    next_form_page
    # email
    find('#root_email').value.tap do |email|
      next if email.blank?
      find('#root_view\:emailConfirmation').set(email)
    end
    next_form_page
    # service
    find('#root_lastServiceBranch').find(:option, 'Army').select_option

    %w[Entry Discharge].each do |type|
      find("#root_last#{type}DateMonth option[value='1']").select_option
      find("#root_last#{type}DateDay option[value='1']").select_option
      find("#root_last#{type}DateYear").set(type == 'Entry' ? '1970' : '1971')
    end
    find('#root_dischargeType option[value="honorable"]').select_option
    next_form_page
    # service special options
    next_form_page

    unless logged_in
      # dd214
      next_form_page
    end

    # compensation
    click('#root_vaCompensationType_3', visible: false)
    next_form_page
    # financial information
    click('#root_discloseFinancialInformationNo', visible: false)
    next_form_page
    # insurance
    click('#root_isMedicaidEligibleNo', visible: false)
    click('#root_isEnrolledMedicarePartANo', visible: false)
    next_form_page
    # other coverage
    click('#root_isCoveredByHealthInsuranceNo', visible: false)
    next_form_page
    # va facility
    find('#root_view\:preferredFacility_view\:facilityState option[value="AL"]').select_option
    find('#root_view\:preferredFacility_vaMedicalFacility option[value="521GE"]').select_option
    next_form_page
    # REVIEW: application
    click('[name="privacyAgreementAccepted"]', visible: false)
    next_form_page
    expect(current_path).to eq('/health-care/apply/application/confirmation')
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end

  it 'logged in application', js: true do
    user = feature_set_user_session

    start_application
    # veteran info
    find('#root_veteranFullName_first').set('first')
    find('#root_veteranFullName_last').set('last')
    next_form_page
    # dob
    find('#root_veteranDateOfBirthMonth').find(:option, 'Jan').select_option
    find('#root_veteranDateOfBirthDay').find(:option, '1').select_option
    find('#root_veteranDateOfBirthYear').set('1950')
    next_form_page
    common_fill_hca_form(true)

    health_care_application = HealthCareApplication.last
    expect(health_care_application.state).to eq('pending')
    # run job and make sure it succeeds
    job = HCA::SubmissionJob.jobs.last
    expect(job['args'][2]).to eq(health_care_application.id)
    binding.pry; fail
    HCA::SubmissionJob.drain
    expect(health_care_application.reload.state).to eq('success')
  end

  it 'anonymous application', js: true do
    start_application
    # user details page
    find('#root_firstName').set('first')
    find('#root_lastName').set('last')
    find('#root_dobMonth').find(:option, 'Jan').select_option
    find('#root_dobDay').find(:option, '1').select_option
    find('#root_dobYear').set('1950')
    find('#root_ssn').set('111-22-3333')
    wait_for_new_url('.usa-button')
    # veteran information
    sleep(1)
    next_form_page
    # dob
    next_form_page

    common_fill_hca_form(false)
  end
end
