# frozen_string_literal: true

RSpec.describe Dbwatcher::Services::MermaidSyntax::Sanitizer do
  describe ".class_name" do
    it "handles simple class names" do
      expect(described_class.class_name("User")).to eq("User")
      expect(described_class.class_name("user")).to eq("user")
    end

    it "handles namespaced class names" do
      expect(described_class.class_name("DoubleEntry::LineMetadata")).to eq("DoubleEntry__LineMetadata")
      expect(described_class.class_name("Admin::User::Profile")).to eq("Admin__User__Profile")
    end

    it "handles deeply nested namespaces" do
      expect(described_class.class_name("A::B::C::D::E")).to eq("A__B__C__D__E")
    end

    it "handles special characters" do
      expect(described_class.class_name("User-Model")).to eq("User_Model")
      expect(described_class.class_name("User Model")).to eq("User_Model")
      expect(described_class.class_name("User@Model")).to eq("User_Model")
    end

    it "handles mixed cases" do
      expect(described_class.class_name("My::Super-Model")).to eq("My__Super_Model")
      expect(described_class.class_name("API::V1::Users")).to eq("API__V1__Users")
    end

    it "handles empty and nil values" do
      expect(described_class.class_name("")).to eq("UnknownClass")
      expect(described_class.class_name(nil)).to eq("UnknownClass")
    end
  end

  describe ".display_name" do
    it "preserves original class names" do
      expect(described_class.display_name("User")).to eq("User")
      expect(described_class.display_name("DoubleEntry::LineMetadata")).to eq("DoubleEntry::LineMetadata")
      expect(described_class.display_name("Admin::User::Profile")).to eq("Admin::User::Profile")
    end

    it "handles empty and nil values" do
      expect(described_class.display_name("")).to eq("UnknownClass")
      expect(described_class.display_name(nil)).to eq("UnknownClass")
    end
  end

  describe ".node_name" do
    it "handles node names with special characters" do
      expect(described_class.node_name("User::Profile")).to eq("User__Profile")
      expect(described_class.node_name("user-profile")).to eq("user_profile")
    end
  end

  describe ".table_name" do
    it "always preserves table case" do
      expect(described_class.table_name("user_profiles")).to eq("user_profiles")
      expect(described_class.table_name("UserProfiles")).to eq("UserProfiles")
      expect(described_class.table_name("legacy_users")).to eq("legacy_users")
    end

    it "handles special characters" do
      expect(described_class.table_name("user-profiles")).to eq("user_profiles")
      expect(described_class.table_name("user profiles")).to eq("user_profiles")
      expect(described_class.table_name("user@profiles")).to eq("user_profiles")
    end
  end

  describe ".label" do
    it "handles labels with quotes and special characters" do
      expect(described_class.label('has "many" items')).to eq('has \\"many\\" items')
      expect(described_class.label("line\nbreak")).to eq("line break")
    end

    it "handles backslash escaping" do
      # Test with a literal backslash character using single quotes
      input_with_backslash = 'test\path'
      expected_output = 'test\\path'
      expect(described_class.label(input_with_backslash)).to eq(expected_output)
    end

    it "handles empty labels" do
      expect(described_class.label("")).to eq("")
      expect(described_class.label(nil)).to eq("")
    end
  end

  describe ".method_name" do
    it "handles method names" do
      expect(described_class.method_name("full_name")).to eq("full_name()")
      expect(described_class.method_name("calculate_total()")).to eq("calculate_total()")
    end

    it "handles special characters in method names" do
      expect(described_class.method_name("user-info")).to eq("user_info()")
      expect(described_class.method_name("user@info")).to eq("user_info()")
    end
  end

  describe ".attribute_type" do
    it "handles attribute types" do
      expect(described_class.attribute_type("string")).to eq("string")
      expect(described_class.attribute_type("integer")).to eq("integer")
      expect(described_class.attribute_type("decimal(10,2)")).to eq("decimal_10_2_")
    end
  end
end
