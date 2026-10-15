const { test } = require('node:test');
const assert = require('node:assert/strict');
const { decision, run } = require('./owner-approval.cjs');
const pr = { number: 1, user: { login: 'contributor' }, head: { sha: 'current' }, state: 'open', base: { ref: 'main' } };
const review = (state, commit = 'current', login = 'yssf-c', id = 1) => ({ id, state, commit_id: commit, user: { login } });
test('owner-authored PRs need no approval', () => assert.equal(decision({ ...pr, user: { login: 'yssf-c' } }, []).state, 'success'));
test('another author needs the owner, not any reviewer', () => {
  assert.equal(decision(pr, []).state, 'failure');
  assert.equal(decision(pr, [review('APPROVED', 'current', 'someone-else')]).state, 'failure');
});
test('approval must cover the exact latest commit', () => {
  assert.equal(decision(pr, [review('APPROVED')]).state, 'success');
  assert.equal(decision(pr, [review('APPROVED', 'old')]).state, 'failure');
});
test('dismissal and requested changes revoke approval', () => {
  for (const state of ['DISMISSED', 'CHANGES_REQUESTED']) {
    assert.equal(decision(pr, [review('APPROVED'), review(state, 'current', 'yssf-c', 2)]).state, 'failure');
  }
});
test('comments do not revoke an otherwise valid approval', () => {
  assert.equal(decision(pr, [review('APPROVED'), review('COMMENTED', 'current', 'yssf-c', 2)]).state, 'success');
});
test('new approval resolves an earlier change request', () => {
  assert.equal(decision(pr, [review('CHANGES_REQUESTED'), review('APPROVED', 'current', 'yssf-c', 2)]).state, 'success');
});
test('shared commit cannot inherit the owner PR exemption', async () => {
  const pulls = [pr, { ...pr, number: 2, user: { login: 'yssf-c' } }];
  const statuses = [];
  const github = { rest: { pulls: { list: 'list', listReviews: 'reviews', get: async ({pull_number}) => ({data: pulls.find(p => p.number === pull_number)}) }, repos: { createCommitStatus: async s => statuses.push(s) } }, paginate: async method => method === 'list' ? pulls : [] };
  await run({ github, context: { repo: {owner: 'yssf-c', repo: 'Gallery-Glow'}, runId: 1 }, core: {info() {}} });
  assert.equal(statuses.length, 1);
  assert.equal(statuses[0].state, 'failure');
});
