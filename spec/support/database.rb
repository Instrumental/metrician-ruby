database = Gemika::Database.new
database.connect

if Gemika::Env.gem?('activerecord', '< 5')
  class ActiveRecord::ConnectionAdapters::Mysql2Adapter
    NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
  end
end

database.rewrite_schema! do

  create_table :users do |t|
    t.string :name
    t.string :email
    t.string :city
  end

  create_table :recipes do |t|
    t.string :name
    t.integer :category_id
  end

  create_table :recipe_ingredients do |t|
    t.string :name
    t.integer :recipe_id
  end

  create_table :recipe_categories do |t|
    t.string :name
  end

end