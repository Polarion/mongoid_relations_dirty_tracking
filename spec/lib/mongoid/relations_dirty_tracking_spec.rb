require 'spec_helper'
require 'pry'

describe Mongoid::RelationsDirtyTracking do
  subject { TestDocument.create }

  its(:changed?)                { should be_false }
  its(:children_changed?)       { should be_false }
  its(:relations_changed?)      { should be_false }
  its(:changed_with_relations?) { should be_false }


  context "embeds_one relationship" do
    context "when adding document" do
      before :each do
        @embedded_doc = TestEmbeddedDocument.new
        subject.one_document = @embedded_doc
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['one_document']).to eq([nil, @embedded_doc.attributes])
        end
      end
    end


    context "when removing document" do
      before :each do
        @embedded_doc = TestEmbeddedDocument.new
        subject.one_document = @embedded_doc
        subject.save!
        subject.one_document = nil
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['one_document']).to eq([@embedded_doc.attributes, nil])
        end
      end
    end


    context "when changing value on embedded document" do
      before :each do
        @embedded_doc = TestEmbeddedDocument.new
        subject.one_document = @embedded_doc
        subject.save!
        subject.one_document.title = 'foobar'
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_true }
      its(:relations_changed?)       { should be_true }
      its(:changed_with_relations?)  { should be_true }
      its(:changes_with_relations)   { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          old_attributes = @embedded_doc.attributes.clone.delete_if {|key, val| key == "title" }
          expect(subject.relation_changes['one_document']).to eq([old_attributes, @embedded_doc.attributes])
        end
      end
    end
  end

  context "embeds_many relationship" do
    context "when adding document" do
      before :each do
        @embedded_doc = TestEmbeddedDocument.new
        subject.many_documents << @embedded_doc
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)       { should be_true }
      its(:changed_with_relations?)  { should be_true }
      its(:changes_with_relations)   { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['many_documents']).to eq([[], [@embedded_doc.attributes]])
        end
      end
    end


    context "when removing document" do
      before :each do
        @embedded_doc = TestEmbeddedDocument.new
        subject.many_documents = [@embedded_doc]
        subject.save!
        subject.many_documents.delete @embedded_doc
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['many_documents']).to eq([[@embedded_doc.attributes], []])
        end
      end
    end
  end


  context "has_one relationship" do
    context "when adding document" do
      before :each do
        @related_doc = TestRelatedDocument.new
        subject.one_related = @related_doc
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['one_related']).to eq([nil, {'_id' => @related_doc._id}])
        end
      end
    end

    context "when removing document" do
      before :each do
        @related_doc = TestRelatedDocument.new
        subject.one_related = @related_doc
        subject.save!
        subject.one_related = nil
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['one_related']).to eq([{'_id' => @related_doc._id}, nil])
        end
      end
    end

    context "when changing document" do
      before :each do
        @related_doc = TestRelatedDocument.new
        subject.one_related = @related_doc
        subject.save!
        subject.one_related = @another_related_doc = TestRelatedDocument.new
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['one_related']).to eq([{'_id' => @related_doc._id}, {'_id' => @another_related_doc._id}])
        end
      end
    end

    context "when changing value on referenced document" do
      before :each do
        @related_doc = TestRelatedDocument.new
        subject.one_related = @related_doc
        subject.save!
        subject.one_related.title = "New title"
      end

      its(:changed?)                { should be_false }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_false }
      its(:changed_with_relations?) { should be_false }
      its(:relation_changes)        { should be_empty }
    end
  end


  context "has_many relationship" do
    context "when adding document" do
      before :each do
        @related_doc = TestRelatedDocument.new
        subject.many_related << @related_doc
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['many_related']).to eq([[], [{'_id' => @related_doc._id}]])
        end
      end
    end

    context "when removing document" do
      before :each do
        @related_doc = TestRelatedDocument.new
        subject.many_related << @related_doc
        subject.save!
        subject.many_related.delete  @related_doc
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['many_related']).to eq([[{'_id' => @related_doc._id}], []])
        end
      end
    end
  end


  context "belongs_to relationship" do
    subject { TestRelatedDocument.create }

    context "when adding document" do
      before :each do
        @doc = TestDocument.create
        subject.test_document = @doc
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['test_document']).to eq([nil, {'test_document_id' => @doc._id}])
        end
      end
    end

    context "when removing document" do
      before :each do
        @doc = TestDocument.create
        subject.test_document = @doc
        subject.save!
        subject.test_document = nil
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['test_document']).to eq([{'test_document_id' => @doc._id}, nil])
        end
      end
    end
  end
end