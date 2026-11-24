#ifndef TASKWORKER_H
#define TASKWORKER_H

#include <QObject>
#include <QThread>
#include <atomic>

// 跑在独立 QThread 里的工作对象（模拟耗时任务，可取消）
class TaskWorker : public QObject
{
    Q_OBJECT

public:
    void requestCancel() { m_cancel = true; }

public slots:
    void doWork(const QString &name, int steps, int intervalMs);

signals:
    void progress(const QString &name, int percent);
    void log(const QString &name, const QString &msg);
    void finished(const QString &name, const QString &result);

private:
    std::atomic_bool m_cancel{false};
};

// 多线程入口：
//  - startTask()  QThread 常驻后台任务（进度/取消）
//  - runParallel() QtConcurrent 多线程并行计算
class TaskRunner : public QObject
{
    Q_OBJECT

public:
    explicit TaskRunner(QObject *parent = nullptr);
    ~TaskRunner() override;

    Q_INVOKABLE void startTask(const QString &name, int steps = 100, int intervalMs = 80);
    Q_INVOKABLE void cancelTask();
    Q_INVOKABLE void runParallel(qint64 upperBound = 2000000);

signals:
    void taskProgress(const QString &name, int percent);
    void taskLog(const QString &name, const QString &msg);
    void taskFinished(const QString &name, const QString &result);
    void parallelFinished(qint64 count, qint64 elapsedMs, int threads);
    void parallelLog(const QString &msg);

private:
    QThread m_thread;
    TaskWorker *m_worker = nullptr;
};

#endif // TASKWORKER_H
