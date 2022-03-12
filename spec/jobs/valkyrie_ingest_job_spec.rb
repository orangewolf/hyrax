# frozen_string_literal: true

require 'hyrax/specs/spy_listener'

RSpec.describe ValkyrieIngestJob do
  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
  let(:upload) { FactoryBot.create(:uploaded_file, file_set_uri: file_set.id) }

  let(:listener) { Hyrax::Specs::AppendingSpyListener.new }
  let(:characterizer) { double(characterize: fits_response) }
  let(:fits_response) { IO.read('spec/fixtures/png_fits.xml') }

  before do
    Hyrax.publisher.subscribe(listener)

    # stub out characterization to avoid system calls. It's important some
    # amount of characterization happens so listeners fire.
    allow(Hydra::FileCharacterization).to receive(:characterize).and_return(fits_response)
  end

  after { Hyrax.publisher.unsubscribe(listener) }

  describe '.perform_now' do
    it 'adds an original_file file to the file_set' do
      described_class.perform_now(upload)

      reloaded_file_set = Hyrax.query_service.find_by(id: file_set.id)
      expect(reloaded_file_set)
        .to have_attached_files(be_original_file)
      expect(reloaded_file_set.title).to eq ["image.jp2"]
      expect(reloaded_file_set.label).to eq "image.jp2"
      expect(reloaded_file_set.file_ids)
        .to contain_exactly(reloaded_file_set.original_file_id)
    end

    it 'makes original_file queryable by use' do
      described_class.perform_now(upload)

      resource = Hyrax.query_service.find_by(id: file_set.id)

      expect(Hyrax.custom_queries.find_original_file(file_set: resource))
        .to be_a Hyrax::FileMetadata
    end

    it 'publishes object.file.uploaded with a FileMetadata' do
      expect { described_class.perform_now(upload) }
        .to change { listener.object_file_uploaded.map(&:payload) }
        .from(be_empty)
        .to contain_exactly(match(metadata: have_attributes(id: an_instance_of(Valkyrie::ID),
                                                            original_filename: upload.file.filename)))
    end

    it 'publishes object.membership.updated for the changed file set' do
      expect { described_class.perform_now(upload) }
        .to change { listener.object_membership_updated.map(&:payload) }
        .from(be_empty)
        .to contain_exactly(match(object: have_attributes(id: file_set.id),
                                  user: upload.user))
    end

    context 'with a thumbnail added' do
      let(:thumbnail_upload) do
        FactoryBot.create(:uploaded_file,
                          file: File.open('spec/fixtures/world.png'),
                          file_set_uri: file_set.id)
      end

      it 'adds an original_file file to the file_set' do
        described_class.perform_now(upload)
        described_class.perform_now(thumbnail_upload, pcdm_use: Hyrax::FileMetadata::Use::THUMBNAIL)

        reloaded_file_set = Hyrax.query_service.find_by(id: file_set.id)
        expect(reloaded_file_set)
          .to have_attached_files(be_original_file, be_thumbnail_file)
        expect(reloaded_file_set.title).to eq ["image.jp2"]
        expect(reloaded_file_set.label).to eq "image.jp2"
        expect(reloaded_file_set.file_ids)
          .to contain_exactly(reloaded_file_set.original_file_id, reloaded_file_set.thumbnail_id)
      end
    end

    context 'with no file_set_uri' do
      let(:upload) { FactoryBot.create(:uploaded_file) }

      it 'raises an error indicating a missing object' do
        expect { described_class.perform_now(upload) }
          .to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end
end
