# frozen_string_literal: true

require "unit/services/diagram_analyzers_helper"

RSpec.describe Dbwatcher::Services::DiagramAnalyzers::InferredRelationshipAnalyzer do
  let(:analyzer) { described_class.new }

  describe "#self_referential_column?" do
    it "identifies common self-referential patterns" do
      expect(analyzer.send(:self_referential_column?, "parent_id", "comments", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "ancestor_id", "categories", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "child_id", "nodes", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "reply_to_id", "messages", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "manager_id", "employees", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "supervisor_id", "staff", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "predecessor_id", "tasks", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "successor_id", "steps", "id")).to be true
    end

    it "identifies table-specific self-references" do
      expect(analyzer.send(:self_referential_column?, "comment_id", "comments", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "category_id", "categories", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "post_id", "posts", "id")).to be false # Not self-referential in posts table
    end

    it "identifies hierarchy pattern prefixes" do
      expect(analyzer.send(:self_referential_column?, "parent_node_id", "nodes", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "child_category_id", "categories", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "ancestor_comment_id", "comments", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "superior_employee_id", "employees", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "manager_staff_id", "staff", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "parent_of_id", "categories", "id")).to be true
    end

    it "identifies relationship patterns" do
      expect(analyzer.send(:self_referential_column?, "related_post_id", "posts", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "linked_product_id", "products", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "connected_node_id", "nodes", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "associated_item_id", "items", "id")).to be true
    end

    it "identifies directional patterns" do
      expect(analyzer.send(:self_referential_column?, "previous_version_id", "documents", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "next_step_id", "steps", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "original_file_id", "files", "id")).to be true
      expect(analyzer.send(:self_referential_column?, "copy_record_id", "records", "id")).to be true
    end

    it "does not identify standard foreign keys as self-referential" do
      expect(analyzer.send(:self_referential_column?, "user_id", "posts", "id")).to be false
      expect(analyzer.send(:self_referential_column?, "post_id", "comments", "id")).to be false
      expect(analyzer.send(:self_referential_column?, "category_id", "products", "id")).to be false
    end

    context "when primary key is not the default 'id'" do
      it "correctly identifies self-references" do
        expect(analyzer.send(:self_referential_column?, "custom_table_id", "custom_table", "custom_id")).to be true
        expect(analyzer.send(:self_referential_column?, "custom_id", "custom_table", "custom_id")).to be false # This is the primary key
      end
    end
  end
end
