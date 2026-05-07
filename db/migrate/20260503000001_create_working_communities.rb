class CreateWorkingCommunities < ActiveRecord::Migration[8.1]
  def change
    create_table :working_communities, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string  :name,                  null: false
      t.text    :purpose,               null: false
      t.string  :jurisdiction,          null: false
      t.integer :founding_team_size,    null: false
      t.text    :business_model,        null: false
      t.string  :legal_form_preference, null: false
      t.timestamps                      null: false
    end

    add_index :working_communities, :created_at
  end
end
