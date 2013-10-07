require 'spec_helper'

describe Mongoid::TrackEmbeddedChanges do
  subject { TestDocument.create }

  its(:changed?)                { should be_false }
  its(:children_changed?)       { should be_false }
  its(:embedded_changed?)       { should be_false }
  its(:changed_with_embedded?)  { should be_false }


  context "when adding embeds_one relationship" do
    before :each do
      @embedded_doc = TestEmbeddedDocument.new
      subject.one_document = @embedded_doc
    end

    its(:changed?)                { should be_true }
    its(:children_changed?)       { should be_false }
    its(:embedded_changed?)       { should be_true }
    its(:changed_with_embedded?)  { should be_true }
    its(:changes_with_embedded)   { should include(subject.embedded_changes) }

    describe "#embedded_changes" do
      it "returns array with differences" do
        expect(subject.embedded_changes['one_document']).to eq([nil, @embedded_doc.attributes])
      end
    end
  end


  context "when removing embeds_one relationship" do
    before :each do
      @embedded_doc = TestEmbeddedDocument.new
      subject.one_document = @embedded_doc
      subject.save!
      subject.one_document = nil
    end

    its(:changed?)                { should be_true }
    its(:children_changed?)       { should be_false }
    its(:embedded_changed?)       { should be_true }
    its(:changed_with_embedded?)  { should be_true }
    its(:changes_with_embedded)   { should include(subject.embedded_changes) }

    describe "#embedded_changes" do
      it "returns array with differences" do
        expect(subject.embedded_changes['one_document']).to eq([@embedded_doc.attributes, nil])
      end
    end
  end


  context "when adding to embeds_many relationship" do
    before :each do
      @embedded_doc = TestEmbeddedDocument.new
      subject.many_documents << @embedded_doc
    end

    its(:changed?)                { should be_true }
    its(:children_changed?)       { should be_false }
    its(:embedded_changed?)       { should be_true }
    its(:changed_with_embedded?)  { should be_true }
    its(:changes_with_embedded)   { should include(subject.embedded_changes) }

    describe "#embedded_changes" do
      it "returns array with differences" do
        expect(subject.embedded_changes['many_documents']).to eq([[], [@embedded_doc.attributes]])
      end
    end
  end


  context "when removing from embeds_many relationship" do
    before :each do
      @embedded_doc = TestEmbeddedDocument.new
      subject.many_documents = [@embedded_doc]
      subject.save!
      subject.many_documents.delete @embedded_doc
    end

    its(:changed?)                { should be_true }
    its(:children_changed?)       { should be_false }
    its(:embedded_changed?)       { should be_true }
    its(:changed_with_embedded?)  { should be_true }
    its(:changes_with_embedded)   { should include(subject.embedded_changes) }

    describe "#embedded_changes" do
      it "returns array with differences" do
        expect(subject.embedded_changes['many_documents']).to eq([[@embedded_doc.attributes], []])
      end
    end
  end


  context "when changing value of field on embedded document" do
    before :each do
      @embedded_doc = TestEmbeddedDocument.new
      subject.one_document = @embedded_doc
      subject.save!
      subject.one_document.title = 'foobar'
    end

    its(:changed?)                { should be_true }
    its(:children_changed?)       { should be_true }
    its(:embedded_changed?)       { should be_true }
    its(:changed_with_embedded?)  { should be_true }
    its(:changes_with_embedded)   { should include(subject.embedded_changes) }

    describe "#embedded_changes" do
      it "returns array with differences" do
        old_attributes = @embedded_doc.attributes.clone.delete_if {|key, val| key == "title" }
        expect(subject.embedded_changes['one_document']).to eq([old_attributes, @embedded_doc.attributes])
      end
    end
  end
end
