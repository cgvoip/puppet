require 'spec_helper'

describe 'cron::hourly' do
  let( :title )  { 'mysql_backup' }
  let( :params ) {{
    :minute  => '59',
    :command => 'mysqldump -u root test_db >some_file'
  }}

  it do
    should contain_cron__job( title ).with(
      'minute'      => params[:minute],
      'hour'        => '*',
      'date'        => '*',
      'month'       => '*',
      'weekday'     => '*',
      'user'        => params[:user] || 'root',
      'environment' => params[:environment] || [],
      'mode'        => params[:mode] || '0644',
      'command'     => params[:command]
    )
  end

  it do
    should contain_file( "job_#{title}" ).with(
      'owner'   => 'root'
    ).with_content(
      /\s+59 \* \* \* \*  root  mysqldump -u root test_db >some_file\n/
    )
  end

end

