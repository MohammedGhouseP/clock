/// Lifecycle of a single task block.
///
/// notStarted -> inProgress -> (paused <-> inProgress)* -> completed | delayed | failed
enum TaskStatus {
  notStarted,
  inProgress,
  paused, // user "waited" / paused mid-task
  completed, // finished within (or close to) planned time
  delayed, // finished, but took noticeably longer than planned
  failed, // given up, or never finished by end of day
}
