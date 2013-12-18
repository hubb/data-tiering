SPEC_CONNECTIONS = {
  :mysql => {
    :adapter  => 'mysql2',
    :database => 'data_tiering_test',
    :encoding => 'utf8',
    :username => 'root',
    :host     => 'localhost'
  },
  :postgresql => {
    :adapter      => 'postgresql',
    :database     => 'data_tiering_test',
    :encoding     => 'unicode',
    :username     => 'root',
    :host         => 'localhost',
    :port         => 5432,
    :pool         => 5,
    :min_messages => 'warning'
  },
  :sqlite => {
    :adapter =>  'sqlite3',
    :database =>  File.join(File.expand_path("..", __FILE__), "data_tiering_test.sqlite")
  }
}

ActiveRecord::Base.establish_connection SPEC_CONNECTIONS[(ENV['TEST_DATABASE'] || :mysql).to_sym]
