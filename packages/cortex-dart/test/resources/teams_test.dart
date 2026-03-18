import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('TeamsResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('list returns teams', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            sampleTeam(id: 'team-1', name: 'Engineering'),
            sampleTeam(id: 'team-2', name: 'Design'),
          ],
        }),
      );

      final teams = await client.teams.list();
      expect(teams, hasLength(2));
      expect(teams.first.name, 'Engineering');
    });

    test('create sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleTeam(), requests),
      );

      final team = await client.teams.create(
        name: 'Engineering',
        description: 'The engineering team',
      );

      expect(team.id, 'team-123');
      expect(team.name, 'Engineering');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['name'], 'Engineering');
      expect(body['description'], 'The engineering team');
    });

    test('create validates empty name', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.teams.create(name: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('get returns team by id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, sampleTeam()),
      );

      final team = await client.teams.get('team-123');
      expect(team.id, 'team-123');
      expect(team.members, hasLength(1));
    });

    test('get validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.teams.get(''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('delete sends DELETE request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.teams.delete('team-123');
      expect(requests.first.method, 'DELETE');
      expect(requests.first.url.path, contains('/api/teams/team-123'));
    });

    test('addMember sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {
          'id': 'member-1',
          'email': 'bob@example.com',
          'role': 'member',
        }, requests),
      );

      final member = await client.teams.addMember(
        teamId: 'team-123',
        email: 'bob@example.com',
        role: 'member',
      );

      expect(member.email, 'bob@example.com');
      expect(member.role, 'member');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['email'], 'bob@example.com');
      expect(body['role'], 'member');
    });

    test('addMember validates empty teamId', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.teams.addMember(
          teamId: '',
          email: 'bob@example.com',
          role: 'member',
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('addMember validates empty email', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.teams.addMember(
          teamId: 'team-123',
          email: '',
          role: 'member',
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('updateMemberRole sends PATCH', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {
          'id': 'member-1',
          'role': 'admin',
        }, requests),
      );

      final member = await client.teams.updateMemberRole(
        teamId: 'team-123',
        memberId: 'member-1',
        role: 'admin',
      );

      expect(member.role, 'admin');
      expect(requests.first.method, 'PATCH');
    });

    test('removeMember sends DELETE', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.teams.removeMember(
        teamId: 'team-123',
        memberId: 'member-1',
      );

      expect(requests.first.method, 'DELETE');
      expect(
        requests.first.url.path,
        contains('/api/teams/team-123/members/member-1'),
      );
    });
  });
}
