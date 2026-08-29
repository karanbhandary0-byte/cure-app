import 'package:flutter_test/flutter_test.dart';
import 'package:cure_flutter/utils/disease_specialty_mapper.dart';

void main() {
  group('DiseaseSpecialtyMapper Tests', () {
    test('Maps fever to General Physician', () {
      final specs = DiseaseSpecialtyMapper.getSpecialtiesForQuery('fever');
      expect(specs, contains('General Physician'));
    });

    test('Maps heart pain to Cardiology', () {
      final specs = DiseaseSpecialtyMapper.getSpecialtiesForQuery('heart pain');
      expect(specs, contains('Cardiology'));
    });

    test('Maps skin rash to Dermatology', () {
      final specs = DiseaseSpecialtyMapper.getSpecialtiesForQuery('skin rash');
      expect(specs, contains('Dermatology'));
    });

    test('Maps diabetes to Endocrinology', () {
      final specs = DiseaseSpecialtyMapper.getSpecialtiesForQuery('diabetes');
      expect(specs, contains('Endocrinology'));
    });

    test('Returns empty list for blank query', () {
      final specs = DiseaseSpecialtyMapper.getSpecialtiesForQuery('   ');
      expect(specs, isEmpty);
    });
  });
}
