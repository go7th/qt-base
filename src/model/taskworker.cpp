#include "taskworker.h"

#include <QElapsedTimer>
#include <QFutureWatcher>
#include <QVector>
#include <QtConcurrent>

void TaskWorker::doWork(const QString &name, int steps, int intervalMs)
{
    m_cancel = false;
    emit log(name,
             tr("后台任务开始，工作线程 id=%1")
                 .arg(reinterpret_cast<quintptr>(QThread::currentThreadId()), 0, 16));
    QElapsedTimer timer;
    timer.start();
    for (int i = 1; i <= steps; ++i) {
        if (m_cancel) {
            emit log(name, tr("任务被取消（已完成 %1%）").arg((i - 1) * 100 / steps));
            emit finished(name, tr("已取消"));
            return;
        }
        QThread::msleep(static_cast<unsigned long>(intervalMs));
        emit progress(name, i * 100 / steps);
    }
    emit finished(name, tr("完成，耗时 %1 ms").arg(timer.elapsed()));
}

TaskRunner::TaskRunner(QObject *parent)
    : QObject(parent)
{
    m_worker = new TaskWorker;
    m_worker->moveToThread(&m_thread);
    connect(&m_thread, &QThread::finished, m_worker, &QObject::deleteLater);
    connect(m_worker, &TaskWorker::progress, this, &TaskRunner::taskProgress);
    connect(m_worker, &TaskWorker::log, this, &TaskRunner::taskLog);
    connect(m_worker, &TaskWorker::finished, this, &TaskRunner::taskFinished);
    m_thread.start();
}

TaskRunner::~TaskRunner()
{
    m_worker->requestCancel();
    m_thread.quit();
    m_thread.wait();
}

void TaskRunner::startTask(const QString &name, int steps, int intervalMs)
{
    // 跨线程投递：任务在工作线程执行，UI 线程不被阻塞
    QMetaObject::invokeMethod(
        m_worker,
        [this, name, steps, intervalMs]() { m_worker->doWork(name, steps, intervalMs); },
        Qt::QueuedConnection);
}

void TaskRunner::cancelTask()
{
    m_worker->requestCancel();
}

void TaskRunner::runParallel(qint64 upperBound)
{
    const int chunks = qMax(2, QThread::idealThreadCount());
    emit parallelLog(tr("QtConcurrent 并行统计 [2, %1) 内素数个数，%2 线程...")
                         .arg(upperBound)
                         .arg(chunks));

    struct Range {
        qint64 from;
        qint64 to;
    };
    QVector<Range> ranges;
    const qint64 span = upperBound / chunks;
    for (int i = 0; i < chunks; ++i) {
        const qint64 from = 2 + i * span;
        const qint64 to = (i == chunks - 1) ? upperBound : 2 + (i + 1) * span;
        ranges.append({from, to});
    }

    auto mapFn = [](const Range &r) -> qint64 {
        qint64 count = 0;
        for (qint64 n = r.from; n < r.to; ++n) {
            bool prime = true;
            for (qint64 d = 2; d * d <= n; ++d) {
                if (n % d == 0) {
                    prime = false;
                    break;
                }
            }
            if (prime)
                ++count;
        }
        return count;
    };
    auto reduceFn = [](qint64 &total, qint64 part) { total += part; };

    auto *watcher = new QFutureWatcher<qint64>(this);
    QElapsedTimer timer;
    timer.start();
    connect(watcher, &QFutureWatcher<qint64>::finished, this,
            [this, watcher, timer, chunks]() {
                const qint64 result = watcher->result();
                watcher->deleteLater();
                emit parallelFinished(result, timer.elapsed(), chunks);
            });
    watcher->setFuture(QtConcurrent::mappedReduced(ranges, mapFn, reduceFn));
}
