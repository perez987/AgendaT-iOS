import Foundation

/// Manages CRUD (create, read, update, delete) operations for phonebook entries
class PhonebookManager {
	/// Saves or updates a contact in the phonebook
	/// - Parameters:
	///   - entry: The phone entry to save
	///   - allEntries: The current array of all entries
	/// - Returns: true if the contact was successfully saved, false otherwise
	static func saveContact(_ entry: PhoneEntry, in allEntries: inout [PhoneEntry]) -> Bool {
		var updatedEntries = allEntries
		// Find if this entry already exists in our list
		let existingIndex = updatedEntries.firstIndex(where: { $0.id == entry.id })
		
		if existingIndex == nil {
			// New contact
			updatedEntries.append(entry)
		} else {
			// Updating existing contact
			updatedEntries[existingIndex!] = entry
		}
		
		guard savePhonebookData(entries: updatedEntries) else { return false }
		allEntries = updatedEntries
		return true
	}
	
	/// Deletes an entry from the phonebook
	/// - Parameters:
	///   - entry: The phone entry to delete
	///   - allEntries: The current array of all entries
	/// - Returns: true if the deletion was successfully saved, false otherwise
	static func deleteEntry(_ entry: PhoneEntry, from allEntries: inout [PhoneEntry]) -> Bool {
		let updatedEntries = allEntries.filter { $0.id != entry.id }
		guard savePhonebookData(entries: updatedEntries) else { return false }
		allEntries = updatedEntries
		return true
	}
}
