import Foundation
import CoreData
import os.log

@available(iOS 13.0, *)
struct PersistentHistoryFetcher {
    let context: NSManagedObjectContext
    let excludeHistoryFromContextWithName: String

    func fetch(fromDate date: Date, transactionLimit: Int = 0) -> [NSPersistentHistoryTransaction] {
        let fetchRequest = createFetchRequest(fromDate: date, limit: transactionLimit)
        return fetchHistory(fetchRequest)
    }

    private func fetchHistory(_ fetchRequest: NSPersistentHistoryChangeRequest) -> [NSPersistentHistoryTransaction] {
        let historyResult: NSPersistentHistoryResult
        do {
            guard let historyExecutionResult = try context.execute(fetchRequest) as? NSPersistentHistoryResult else {
                fatalError("Unexpected return type when fetching transaction history")
            }
            historyResult = historyExecutionResult
        } catch {
            os_log(.error, "Failed to fetch transaction history")
            return []
        }
        return historyResult.result as! [NSPersistentHistoryTransaction]
    }

    private func createFetchRequest(fromDate date: Date, limit: Int = 0) -> NSPersistentHistoryChangeRequest {
        let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
        historyFetchRequest.fetchRequest = fetchRequest(limit: limit)
        return historyFetchRequest
    }

    private func fetchRequest(limit: Int = 0) -> NSFetchRequest<NSFetchRequestResult>? {
        guard let fetchRequest = NSPersistentHistoryTransaction.fetchRequest else {
            os_log(.error, "NSPersistentHistoryTransaction.fetchRequest was nil")
            return nil
        }

        // Only look at transactions not from the excluded context
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "%K == NULL", #keyPath(NSPersistentHistoryTransaction.contextName)),
            NSPredicate(format: "%K != %@", #keyPath(NSPersistentHistoryTransaction.contextName), excludeHistoryFromContextWithName)
        ])
        // TODO: We are not specifying an order here. Is the ordering automatic?
        //fetchRequest.sortDescriptors = [NSSortDescriptor(\NSPersistentHistoryTransaction.timestamp)]
        fetchRequest.fetchLimit = limit

        return fetchRequest
    }

    func deleteHistory(beforeToken token: NSPersistentHistoryToken) {
        let deletionRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: token)
        do {
            try context.execute(deletionRequest)
        } catch {
            assertionFailure("Failed to delete persistent history")
        }
    }
}