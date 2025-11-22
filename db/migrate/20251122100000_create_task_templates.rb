class CreateTaskTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :task_templates, id: :uuid do |t|
      t.string :name, null: false
      t.text :command_template, null: false
      t.text :description
      t.string :category, null: false
      t.jsonb :default_parameters, default: {}
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :task_templates, :category
    add_index :task_templates, :active
  end
end
