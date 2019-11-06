module FindAPIHelper
  def stub_find_api_course_200(provider_code, course_code, course_name)
    stub_find_api_course(provider_code, course_code)
      .to_return(
        status: 200,
        headers: { 'Content-Type': 'application/vnd.api+json' },
        body: {
          'data' => {
            'id' => '1',
            'type' => 'courses',
            'attributes' => {
              'course_code' => course_code,
              'name' => course_name,
              'provider_code' => provider_code,
            },
          },
          'jsonapi' => { 'version' => '1.0' },
        }.to_json,
      )
  end

  def stub_find_api_course_timeout(provider_code, course_code)
    stub_find_api_course(provider_code, course_code)
      .to_timeout
  end

  def stub_find_api_course_404(provider_code, course_code)
    stub_find_api_course(provider_code, course_code)
      .to_return(status: 404)
  end

  def stub_find_api_course_503(provider_code, course_code)
    stub_find_api_course(provider_code, course_code)
      .to_return(status: 503)
  end

  def stub_find_api_provider_200(provider_code: 'ABC', provider_name: 'Dummy Provider', course_code: 'X130', site_code: 'X')
    stub_find_api_provider(provider_code)
      .to_return(
        status: 200,
        headers: { 'Content-Type': 'application/vnd.api+json' },
        body: {
          'data': {
            'id': '1',
            'type': 'providers',
            'attributes': {
              'provider_name': provider_name,
              'provider_code': provider_code,
            },
            'relationships': {
              'sites': {
                'data': [
                  { 'id': '1', 'type': 'sites' },
                ],
              },
              'courses': {
                'data': [
                  { 'id': '1', 'type': 'courses' },
                ],
              },
            },
          },
          'included': [
            {
              'id': '1',
              'type': 'sites',
              'attributes': {
                'code': site_code,
                'location_name': 'Main Site',
              },
            },
            {
              'id': '1',
              'type': 'courses',
              'attributes': {
                'course_code': course_code,
                'name': 'Primary',
                'level': 'primary',
                'start_date': 'September 2019',
              },
              'relationships': {
                'sites': {
                  'data': [
                    { 'id': '1', 'type': 'sites' },
                  ],
                },
              },
            },
          ],
          'jsonapi': { 'version': '1.0' },
        }.to_json,
      )
  end

private

  def stub_find_api_provider(provider_code)
    stub_request(:get, ENV.fetch('FIND_BASE_URL') +
      'recruitment_cycles/2020' \
      "/providers/#{provider_code}?include=sites,courses.sites")
  end

  def stub_find_api_course(provider_code, course_code)
    stub_request(:get, ENV.fetch('FIND_BASE_URL') +
      'recruitment_cycles/2020' \
      "/providers/#{provider_code}" \
      "/courses/#{course_code}")
  end
end
