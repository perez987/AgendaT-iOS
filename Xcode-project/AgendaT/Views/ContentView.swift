import SwiftUI

struct ContentView: View {
	@State private var allEntries: [PhoneEntry] = []
	@State private var filteredEntries: [PhoneEntry] = []
	@State private var searchText = ""
	@State private var selectedLetter: String?
	@State private var sortField: SortField = .name
	@State private var sortAscending = true
	@State private var editingEntry: PhoneEntry?
	@State private var entryToDelete: PhoneEntry?
	@State private var showingDeleteAlert = false
	@State private var showingStorageError = false
	@State private var hasLoaded = false

	private let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					searchControls
					alphabetControls
					HStack {
						Text(String(format: localized("records_shown"), filteredEntries.count))
							.font(.subheadline)
							.foregroundStyle(.secondary)
						Spacer()
						sortMenu
					}
					if filteredEntries.isEmpty {
						Text(localized("no_contacts"))
							.foregroundStyle(.secondary)
							.frame(maxWidth: .infinity)
							.padding(.vertical)
					}
					LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
						ForEach(filteredEntries) { entry in
							contactCard(entry)
						}
					}
				}
				.padding()
			}
			.scrollDismissesKeyboard(.interactively)
			.background(Color(uiColor: .systemGroupedBackground))
			.navigationTitle(localized("phone_numbers"))
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						let newId = (allEntries.map(\.id).max() ?? 0) + 1
						editingEntry = PhoneEntry(id: newId, name: "", phone1: "", phone2: "")
					} label: {
						Label(localized("add_contact"), systemImage: "plus")
					}
				}
			}
		}
		.onAppear {
			guard !hasLoaded else { return }
			hasLoaded = true
			allEntries = loadPhonebookData()
			applyFilters()
		}
		.sheet(item: $editingEntry) { entry in
			EditContactView(
				entry: entry,
				isNew: !allEntries.contains(where: { $0.id == entry.id }),
				onSave: { updatedEntry in
					guard PhonebookManager.saveContact(updatedEntry, in: &allEntries) else {
						return false
					}
					applyFilters()
					editingEntry = nil
					return true
				},
				onCancel: { editingEntry = nil }
			)
		}
		.alert(localized("delete_confirmation_title"), isPresented: $showingDeleteAlert) {
			Button(localized("cancel"), role: .cancel) { entryToDelete = nil }
			Button(localized("delete"), role: .destructive) {
				if let entry = entryToDelete {
					if PhonebookManager.deleteEntry(entry, from: &allEntries) {
						applyFilters()
					} else {
						showingStorageError = true
					}
				}
				entryToDelete = nil
			}
		} message: {
			if let entry = entryToDelete {
				Text(String(format: localized("delete_confirmation_message"), entry.name))
			}
		}
		.alert(localized("storage_error_title"), isPresented: $showingStorageError) {
			Button(localized("ok"), role: .cancel) {}
		} message: {
			Text(localized("storage_error_message"))
		}
	}

	private var searchControls: some View {
		VStack(alignment: .leading, spacing: 8) {
			TextField(localized("search_by_name"), text: $searchText)
				.textFieldStyle(.roundedBorder)
				.submitLabel(.search)
				.onSubmit { applyFilters() }
			ViewThatFits(in: .horizontal) {
				HStack {
					filterButtons
				}
				VStack(alignment: .leading) {
					filterButtons
				}
			}
		}
	}

	@ViewBuilder
	private var filterButtons: some View {
		Button(localized("show_button")) { applyFilters() }
			.buttonStyle(.borderedProminent)
			.frame(minHeight: 44)
		Button(localized("clear_filters_button")) {
			searchText = ""
			selectedLetter = nil
			applyFilters()
		}
		.buttonStyle(.bordered)
		.frame(minHeight: 44)
	}

	private var alphabetControls: some View {
		LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 4), count: (alphabet.count + 1) / 2), spacing: 8) {
			ForEach(alphabet, id: \.self) { letter in
				Button {
					selectedLetter = selectedLetter == letter ? nil : letter
					applyFilters()
				} label: {
					Text(letter)
						.font(.headline)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
						.frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
						.background(selectedLetter == letter ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground))
						.foregroundStyle(selectedLetter == letter ? Color.white : Color.primary)
						.clipShape(RoundedRectangle(cornerRadius: 8))
				}
				.buttonStyle(.plain)
				.accessibilityAddTraits(selectedLetter == letter ? [.isSelected] : [])
			}
		}
	}

	private var sortMenu: some View {
		Menu {
			ForEach(SortField.allCases, id: \.self) { field in
				Button {
					if sortField == field {
						sortAscending.toggle()
					} else {
						sortField = field
						sortAscending = true
					}
					filteredEntries = FilterSortManager.sortEntries(filteredEntries, by: sortField, ascending: sortAscending)
				} label: {
					if sortField == field {
						Label(localized(field.localizationKey), systemImage: sortAscending ? "chevron.up" : "chevron.down")
					} else {
						Text(localized(field.localizationKey))
					}
				}
			}
		} label: {
			Label(localized(sortField.localizationKey), systemImage: sortAscending ? "arrow.up" : "arrow.down")
				.frame(minHeight: 44)
		}
		.accessibilityLabel(localized("sort_contacts"))
	}

	private func contactCard(_ entry: PhoneEntry) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Button {
				editingEntry = entry
			} label: {
				VStack(alignment: .leading, spacing: 12) {
					Text(entry.name)
						.font(.headline)
					phoneLabel("header_phone1", number: entry.phone1)
					if !entry.phone2.isEmpty {
						phoneLabel("header_phone2", number: entry.phone2)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.contentShape(Rectangle())
			}
			.buttonStyle(.plain)
			.accessibilityHint(localized("edit_contact_title"))
			HStack {
				Text("\(localized("id_label")) \(entry.id)")
					.font(.caption)
					.foregroundStyle(.secondary)
				Spacer()
				Button(role: .destructive) {
					entryToDelete = entry
					showingDeleteAlert = true
				} label: {
					Label(localized("delete"), systemImage: "trash")
						.frame(minHeight: 44)
				}
				.buttonStyle(.borderless)
			}
		}
		.padding()
		.background(Color(uiColor: .secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}

	private func phoneLabel(_ key: String, number: String) -> some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(localized(key))
				.font(.caption)
				.foregroundStyle(.secondary)
			Text(PhoneEntry.formatPhoneNumber(number))
		}
	}

	private func applyFilters() {
		filteredEntries = FilterSortManager.applyFilters(
			to: allEntries,
			selectedLetter: selectedLetter,
			searchText: searchText,
			sortField: sortField,
			sortAscending: sortAscending
		)
	}
}

#Preview {
	ContentView()
}

struct EditContactView: View {
	@State private var name: String
	@State private var phone1: String
	@State private var phone2: String
	@State private var showValidationError = false
	@State private var validationErrorMessage = ""
	@State private var showingStorageError = false
	let id: Int
	let isNew: Bool
	let onSave: (PhoneEntry) -> Bool
	let onCancel: () -> Void

	init(entry: PhoneEntry, isNew: Bool, onSave: @escaping (PhoneEntry) -> Bool, onCancel: @escaping () -> Void) {
		_name = State(initialValue: entry.name)
		_phone1 = State(initialValue: entry.phone1)
		_phone2 = State(initialValue: entry.phone2)
		id = entry.id
		self.isNew = isNew
		self.onSave = onSave
		self.onCancel = onCancel
	}

	var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField(localized("name_label"), text: $name)
						.textContentType(.name)
						.textInputAutocapitalization(.words)
					TextField(localized("phone1_label"), text: $phone1)
						.keyboardType(.numberPad)
						.textContentType(.telephoneNumber)
						.onChange(of: phone1) { phone1 = $0.filter(\.isNumber) }
					TextField(localized("phone2_label"), text: $phone2)
						.keyboardType(.numberPad)
						.textContentType(.telephoneNumber)
						.onChange(of: phone2) { phone2 = $0.filter(\.isNumber) }
					LabeledContent(localized("id_label"), value: String(id))
				}
			}
			.scrollDismissesKeyboard(.interactively)
			.navigationTitle(localized(isNew ? "add_contact_title" : "edit_contact_title"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(localized("cancel"), action: onCancel)
				}
				ToolbarItem(placement: .confirmationAction) {
					Button(localized(isNew ? "add" : "save"), action: save)
						.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
		}
		.interactiveDismissDisabled()
		.alert(localized("validation_error_title"), isPresented: $showValidationError) {
			Button(localized("ok"), role: .cancel) {}
		} message: {
			Text(validationErrorMessage)
		}
		.alert(localized("storage_error_title"), isPresented: $showingStorageError) {
			Button(localized("ok"), role: .cancel) {}
		} message: {
			Text(localized("storage_error_message"))
		}
	}

	private func save() {
		if phone1.isEmpty {
			validationErrorMessage = localized("phone1_required_error")
			showValidationError = true
			return
		}
		guard PhoneEntry.validatePhoneNumber(phone1), PhoneEntry.validatePhoneNumber(phone2) else {
			validationErrorMessage = localized("invalid_phone_error")
			showValidationError = true
			return
		}
		let entry = PhoneEntry(id: id, name: name.trimmingCharacters(in: .whitespacesAndNewlines), phone1: phone1, phone2: phone2)
		if !onSave(entry) {
			showingStorageError = true
		}
	}
}
