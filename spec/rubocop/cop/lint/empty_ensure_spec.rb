# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Lint::EmptyEnsure do
  subject(:cop) { described_class.new }

  it 'registers an offense for empty ensure' do
    expect_offense(<<~RUBY)
      begin
        something
      ensure
      ^^^^^^ Empty `ensure` block detected.
      end
    RUBY
  end

  it 'autocorrects for empty ensure' do
    corrected = autocorrect_source(<<~RUBY)
      begin
        something
      ensure
      end
    RUBY
    expect(corrected).to eq(<<~RUBY)
      begin
        something

      end
    RUBY
  end

  it 'does not register an offense for non-empty ensure' do
    expect_no_offenses(<<~RUBY)
      begin
        something
        return
      ensure
        file.close
      end
    RUBY
  end
end
