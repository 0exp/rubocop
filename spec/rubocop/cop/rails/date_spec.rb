# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Rails::Date, :config do
  subject(:cop) { described_class.new(config) }

  context 'when EnforcedStyle is "strict"' do
    let(:cop_config) { { 'EnforcedStyle' => 'strict' } }

    shared_examples 'offense' do |method, message|
      it "registers an offense for #{method}" do
        inspect_source(method)
        expect(cop.messages).to eq([message])
      end
    end

    %w[today yesterday tomorrow].each do |day|
      it_behaves_like(
        'offense',
        "Date.#{day}",
        "Do not use `Date.#{day}` without zone. Use `Time.zone.#{day}` instead."
      )

      it_behaves_like(
        'offense',
        "::Date.#{day}",
        "Do not use `Date.#{day}` without zone. Use `Time.zone.#{day}` instead."
      )

      it "accepts Some::Date.#{day}" do
        expect_no_offenses("Some::Date.#{day}")
      end
    end

    context 'when using Date.current' do
      it_behaves_like(
        'offense',
        'Date.current',
        'Do not use `Date.current` without zone. Use `Time.zone.today` instead.'
      )

      it_behaves_like(
        'offense',
        '::Date.current',
        'Do not use `Date.current` without zone. Use `Time.zone.today` instead.'
      )

      it 'accepts Some::Date.current' do
        expect_no_offenses('Some::Date.current')
      end
    end

    %w[to_time to_time_in_current_zone].each do |method|
      it "registers an offense for ##{method}" do
        inspect_source("date.#{method}")
        expect(cop.offenses.size).to eq(1)
      end

      context 'when using safe navigation operator' do
        it "registers an offense for ##{method}" do
          inspect_source("date&.#{method}")
          expect(cop.offenses.size).to eq(1)
        end
      end

      it "accepts variable named #{method}" do
        expect_no_offenses("#{method} = 1")
      end

      it "accepts variable #{method} as range end" do
        expect_no_offenses("date..#{method}")
      end
    end

    context 'when a zone is provided' do
      it 'does not register an offense' do
        expect_no_offenses('date.to_time(:utc)')
      end
    end

    context 'when a string literal with timezone' do
      it 'does not register an offense' do
        expect_no_offenses('"2016-07-12 14:36:31 +0100".to_time(:utc)')
      end
    end

    context 'when a string literal without timezone' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          "2016-07-12 14:36:31".to_time(:utc)
                                ^^^^^^^ Do not use `to_time` on Date objects, because they know nothing about the time zone in use.
        RUBY
      end
    end

    context 'when a string literal with "Z"-style UTC timezone' do
      it 'does not register an offense' do
        expect_no_offenses('"2017-09-22T22:46:06.497Z".to_time(:utc)')
      end
    end

    it 'does not blow up in the presence of a single constant to inspect' do
      expect_no_offenses('A')
    end

    RuboCop::Cop::Rails::TimeZone::ACCEPTED_METHODS.each do |a_method|
      it "registers an offense for val.to_time.#{a_method}" do
        inspect_source("val.to_time.#{a_method}")
        expect(cop.offenses.size).to eq(1)
      end
    end

    it 'registers an offense for #to_time_in_current_zone' do
      expect_offense(<<~RUBY)
        "2016-07-12 14:36:31".to_time_in_current_zone
                              ^^^^^^^^^^^^^^^^^^^^^^^ `to_time_in_current_zone` is deprecated. Use `in_time_zone` instead.
      RUBY
    end
  end

  context 'when EnforcedStyle is "flexible"' do
    let(:cop_config) { { 'EnforcedStyle' => 'flexible' } }

    %w[current yesterday tomorrow].each do |day|
      it "accepts Date.#{day}" do
        expect_no_offenses("Date.#{day}")
      end
    end

    it 'registers an offense for Date.today' do
      expect_offense(<<~RUBY)
        Date.today
             ^^^^^ Do not use `Date.today` without zone. Use `Time.zone.today` instead.
      RUBY
    end

    RuboCop::Cop::Rails::TimeZone::ACCEPTED_METHODS.each do |a_method|
      it "accepts val.to_time.#{a_method}" do
        expect_no_offenses("val.to_time.#{a_method}")
      end
    end

    it 'registers an offense for #to_time_in_current_zone' do
      expect_offense(<<~RUBY)
        "2016-07-12 14:36:31".to_time_in_current_zone
                              ^^^^^^^^^^^^^^^^^^^^^^^ `to_time_in_current_zone` is deprecated. Use `in_time_zone` instead.
      RUBY
    end
  end
end
