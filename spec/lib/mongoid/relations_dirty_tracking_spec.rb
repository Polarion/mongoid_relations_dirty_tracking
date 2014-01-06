require 'spec_helper'


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

    context "when just updated_at is changed on embedded document" do
      before :each do
        embedded_doc = Class.new(TestEmbeddedDocument) { include Mongoid::Timestamps }.new
        subject.one_document = @embedded_doc
        subject.save!
        embedded_doc.updated_at = Time.now
      end
      its(:changed?) { should be_false }
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


  context "has_and_belongs_to_many relationship" do
    context "when adding document" do
      before :each do
        @related_doc = TestRelatedDocument.new
        subject.many_to_many_related << @related_doc
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['many_to_many_related']).to eq([[], [{'_id' => @related_doc._id}]])
        end
      end
    end

    context "when removing document" do
      before :each do
        @related_doc = TestRelatedDocument.new
        subject.many_to_many_related << @related_doc
        subject.save!
        subject.many_to_many_related.delete  @related_doc
      end

      its(:changed?)                { should be_true }
      its(:children_changed?)       { should be_false }
      its(:relations_changed?)      { should be_true }
      its(:changed_with_relations?) { should be_true }
      its(:changes_with_relations)  { should include(subject.relation_changes) }

      describe "#relation_changes" do
        it "returns array with differences" do
          expect(subject.relation_changes['many_to_many_related']).to eq([[{'_id' => @related_doc._id}], []])
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


  describe ".track_relation?" do
    context "with only options" do
      it "do tracks only specified relations" do
        expect(TestDocumentWithOnlyOption.track_relation? :many_documents).to be_true
        expect(TestDocumentWithOnlyOption.track_relation? :one_related).to be_false
      end
    end

    context "with except options" do
      it "do no track excluded relations" do
        expect(TestDocumentWithExceptOption.track_relation? 'many_documents').to be_false
        expect(TestDocumentWithExceptOption.track_relation? 'one_related').to be_true
      end
    end
  end


  describe "by befault the versions relation is not tracked" do
    context "when not called 'relations_dirty_tracking'" do
      it "'versions' is excluded from tracing" do
        expect(Class.new(TestDocument).relations_dirty_tracking_options[:except]).to include('versions')
      end
    end

    context "when called 'relations_dirty_tracking' with only" do
      it "'versions' is excluded from tracing" do
        klass = Class.new(TestDocument) { relations_dirty_tracking(only: 'foobar') }
        expect(klass.relations_dirty_tracking_options[:except]).to include('versions')
      end
    end

    context "when called 'relations_dirty_tracking' with except" do
      it "'versions' is excluded from tracing" do
        klass = Class.new(TestDocument) { relations_dirty_tracking(except: 'foobar') }
        expect(klass.relations_dirty_tracking_options[:except]).to include('versions')
        expect(klass.relations_dirty_tracking_options[:except]).to include('foobar')
      end
    end
  end
end
