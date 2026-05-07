class CreateFoundingStarterPacks < ActiveRecord::Migration[8.1]
  def change
    create_table :founding_starter_packs, id: :uuid do |t|
      t.references :working_community, null: false, foreign_key: true,
                                       type: :uuid, index: { unique: true }
      t.text     :conversation_summary
      t.text     :business_model_canvas
      t.text     :legal_form_comparison
      t.text     :open_questions
      t.text     :gemini_raw
      t.datetime :generated_at
      t.timestamps null: false
    end
  end
end
