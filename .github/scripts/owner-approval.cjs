'use strict';

// Only a decisive review from this account can approve somebody else's PR.
const OWNER = 'yssf-c';
function decision(pr, reviews) {
  if (pr.user.login.toLowerCase() === OWNER) {
    return { state: 'success', description: 'Owner-authored PR: no approval required.' };
  }
  const latest = reviews
    .filter(r => r.user?.login?.toLowerCase() === OWNER &&
      ['APPROVED', 'CHANGES_REQUESTED', 'DISMISSED'].includes(r.state))
    .sort((a, b) => b.id - a.id)[0];
  return latest?.state === 'APPROVED' && latest.commit_id === pr.head.sha
    ? { state: 'success', description: 'Youssef approved the current commit.' }
    : { state: 'failure', description: 'Waiting for yssf-c to approve the current commit.' };
}

async function run({ github, context, core }) {
  const repo = context.repo;
  const pulls = await github.paginate(github.rest.pulls.list, {
    ...repo, state: 'open', base: 'main', per_page: 100
  });
  const bySHA = new Map();
  for (const pull of pulls) {
    const { data: pr } = await github.rest.pulls.get({ ...repo, pull_number: pull.number });
    if (pr.state !== 'open' || pr.base.ref !== 'main') continue;
    const reviews = await github.paginate(github.rest.pulls.listReviews, {
      ...repo, pull_number: pr.number, per_page: 100
    });
    const result = decision(pr, reviews);
    const group = bySHA.get(pr.head.sha) ?? [];
    group.push({ number: pr.number, ...result });
    bySHA.set(pr.head.sha, group);
  }
  // Statuses belong to commits. Never let an owner-authored PR approve a second
  // PR by another author that happens to point at the same commit.
  for (const [sha, results] of bySHA) {
    const result = results.find(r => r.state !== 'success') ?? results[0];
    await github.rest.repos.createCommitStatus({
      ...repo, sha, context: 'Owner approval', state: result.state,
      description: result.description,
      target_url: `https://github.com/${repo.owner}/${repo.repo}/actions/runs/${context.runId}`
    });
    core.info(`${sha}: ${result.description}`);
  }
}
module.exports = { decision, run };
