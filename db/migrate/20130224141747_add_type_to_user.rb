class AddTypeToUser < ActiveRecord::Migration
  def up
    # for polymorphism
    add_column :users, :type, :string

    # make all "users" HdoUsers
    User.update_all ["type = ?", 'HdoUser']

    # add columns for representatives
    change_table :users do |t|
      t.string   "external_id"
      t.string   "first_name"
      t.string   "last_name"
      t.integer  "district_id"
      t.datetime "date_of_birth"
      t.datetime "date_of_death"
      t.string   "slug"
      t.string   "image_uid"
      t.string   "image_name"
      t.string   "twitter_id"
    end

    # migrate the representatives (set their id to the id they had plus 200000 or something like that to guarantee no crashes)
    execute <<-SQL
      INSERT INTO users (type, id, external_id, first_name, last_name, created_at, updated_at, district_id, date_of_birth, date_of_death, slug, image_uid, image_name, twitter_id, email)
      SELECT 'Representative', r.id + 200000, r.external_id, r.first_name, r.last_name, r.created_at, r.updated_at, r.district_id, r.date_of_birth, r.date_of_death, r.slug, r.image_uid, r.image_name, r.twitter_id, COALESCE(r.email, r.external_id || '@no-email.stortinget.no')
      FROM representatives AS r;
    SQL

    # update all representative_id associations form all other tables to be 200000 higher
    execute "UPDATE answers SET representative_id = representative_id + 200000;"
    execute "UPDATE committee_memberships SET representative_id = representative_id + 200000;"
    execute "UPDATE party_memberships SET representative_id = representative_id + 200000;"
      # this is commented because representative_id is a varchar on propositions and not integer. why is that? they are all null anyway.
    # execute "UPDATE propositions SET representative_id = CASE WHEN representative_id is null THEN null ELSE representative_id + 200000 END;"
    execute "UPDATE vote_results SET representative_id = representative_id + 200000;"


    # drop table representatives
    drop_table :representatives
  end

  def down
    # recreate table for representatives
    create_table :representatives do |t|
      t.string   :external_id
      t.string   :first_name
      t.string   :last_name
      t.datetime :created_at,    :null => false
      t.datetime :updated_at,    :null => false
      t.integer  :district_id
      t.datetime :date_of_birth
      t.datetime :date_of_death
      t.string   :slug
      t.string   :image_uid
      t.string   :image_name
      t.string   :twitter_id
      t.string   :email
    end

    # migrate representatives back to their own table, set their id to what they have minus 200000
    execute <<-SQL
      INSERT INTO representatives (id, external_id, first_name, last_name, created_at, updated_at, district_id, date_of_birth, date_of_death, slug, image_uid, image_name, twitter_id, email)
      SELECT u.id - 200000, u.external_id, u.first_name, u.last_name, u.created_at, u.updated_at, u.district_id, u.date_of_birth, u.date_of_death, u.slug, u.image_uid, u.image_name, u.twitter_id, NULLIF(u.email, u.external_id || '@no-email.stortinget.no')
      FROM users AS u
      WHERE u.type = 'Representative';
    SQL

    # update all representative_id associations in other tabls to be 200000 lower
    execute "UPDATE answers SET representative_id = representative_id - 200000;"
    execute "UPDATE committee_memberships SET representative_id = representative_id - 200000;"
    execute "UPDATE party_memberships SET representative_id = representative_id - 200000;"
    # execute "UPDATE propositions SET representative_id = representative_id - 200000;"
    execute "UPDATE vote_results SET representative_id = representative_id - 200000;"

    # remove representatives from users table
    execute "DELETE FROM users WHERE type='Representative'"

    # remove rep columns from users table
    remove_column :users, :type
    remove_column :users, :external_id
    remove_column :users, :first_name
    remove_column :users, :last_name
    remove_column :users, :district_id
    remove_column :users, :date_of_birth
    remove_column :users, :date_of_death
    remove_column :users, :slug
    remove_column :users, :image_uid
    remove_column :users, :image_name
    remove_column :users, :twitter_id
  end
end
