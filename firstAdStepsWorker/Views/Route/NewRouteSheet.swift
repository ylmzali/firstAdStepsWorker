import SwiftUI

struct NewRouteSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = RouteViewModel(
        routes: [],
        formVal: Route(
            id: UUID().uuidString,
            userId: SessionManager.shared.currentUser?.id ?? "",
            title: "",
            description: "",
            status: .request_received,
            assignedDate: nil,
            completion: 0,
            shareWithEmployees: false,
            sharedEmployeeIds: [],
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    )
    @StateObject private var employeeViewModel = EmployeeViewModel()
    
    @State private var selectedDate = Date()
    @State private var errorMessage: String?
    @State private var shareWithEmployees = false
    @State private var shareWithEmployeesActive = false
    @State private var showSuccessView = false
    @State private var createdRoute: Route?
    
    let onRouteCreated: (() -> Void)?
    
    init(onRouteCreated: (() -> Void)? = nil) {
        self.onRouteCreated = onRouteCreated
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        titleSection
                        dateSection
                        sharingSection
                        descriptionSection
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Yeni Rota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveRoute()
                    }
                    .foregroundColor(.white)
                    .disabled(viewModel.formVal.title.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Kapat") {
                            hideKeyboard()
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                }
            }
            .onAppear {
                if shareWithEmployees {
                    employeeViewModel.loadCompanyEmployees()
                }
                employeeViewModel.loadCompanyEmployees()
            }
            .onChange(of: shareWithEmployees) { newValue in
                if newValue {
                    shareWithEmployeesActive = true
                    employeeViewModel.loadCompanyEmployees()
                } else {
                    shareWithEmployeesActive = false
                    employeeViewModel.clearSelection()
                }
            }
            .sheet(isPresented: $showSuccessView) {
                if let route = createdRoute {
                    RouteCreationSuccessView(
                        route: route,
                        onNewRoute: {
                            // Form'u resetle
                            viewModel.resetForm()
                            selectedDate = Date()
                            shareWithEmployees = false
                            shareWithEmployeesActive = false
                            errorMessage = nil
                            employeeViewModel.clearSelection()
                            // Sheet'i kapat
                            dismiss()
                        }
                    )
                }
            }
            .onChange(of: showSuccessView) { isPresented in
                if !isPresented {
                    // Sheet kapandığında form'u resetle
                    viewModel.resetForm()
                    selectedDate = Date()
                    shareWithEmployees = false
                    shareWithEmployeesActive = false
                    errorMessage = nil
                    employeeViewModel.clearSelection()
                    createdRoute = nil
                }
            }
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reklam Başlığı")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("Reklam başlığını girin", text: $viewModel.formVal.title, prompt: Text("Reklam başlığını girin").foregroundColor(Color.white.opacity(0.5)))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .accentColor(.white)
                .tint(.white)
        }
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reklam Tarihi")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 8) {

                DatePicker("En az üç gün sonrasına rezervasyon yapabilirsiniz!", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .colorScheme(.dark)
                    .foregroundColor(Color.white.opacity(0.5))
                    .onChange(of: selectedDate) { newValue in
                        viewModel.formVal.assignedDate = ISO8601DateFormatter().string(from: newValue)
                        
                    }

            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                    )
            )
            .cornerRadius(12)
        }
    }
    
    private var sharingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reklam Yönetim Paylaşımı")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Çalışanlarla Paylaş", isOn: $shareWithEmployees)
                    .foregroundColor(Color.white.opacity(0.5))
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                if shareWithEmployeesActive {
                    sharingEmployeeUsersSection
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(shareWithEmployeesActive ? Color.blue : Color.white.opacity(0.2), lineWidth: 1.2)
                    )
                    .clipped()
            )
            .cornerRadius(12)
        }
    }
    
    private var sharingEmployeeUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Çalışanları Seçin")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                if !employeeViewModel.employees.isEmpty {
                    HStack(spacing: 8) {
                        Button("Tümünü Seç") {
                            employeeViewModel.selectAllEmployees()
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                        
                        Button("Temizle") {
                            employeeViewModel.clearSelection()
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    }
                }
            }
            
            if employeeViewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                    Text("Çalışanlar yükleniyor...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else if let error = employeeViewModel.errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding()
            } else if employeeViewModel.employees.isEmpty {
                Text("Şirketinizde henüz çalışan bulunmuyor")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(employeeViewModel.employees) { employee in
                            HStack {
                                Button(action: {
                                    employeeViewModel.toggleEmployeeSelection(employee)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: employeeViewModel.isEmployeeSelected(employee) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(employeeViewModel.isEmployeeSelected(employee) ? .blue : .white.opacity(0.5))
                                            .font(.system(size: 24))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(employee.fullName)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Text(employee.email)
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.05))
                            )
                        }
                    }
                }
                .frame(maxHeight: 230)
                
                // Seçili çalışan sayısını göster
                if employeeViewModel.hasSelectedEmployees() {
                    Text("\(employeeViewModel.getSelectedCount()) çalışan seçildi")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                )
                .clipped()
        )
        .cornerRadius(12)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Açıklama")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            
            TextEditor(text: $viewModel.formVal.description)
                .frame(height: 150)
                .foregroundColor(.white)
                .padding()
                .textEditorStyle(PlainTextEditorStyle())
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .accentColor(.white)
                .tint(.white)
        }
    }
    
    private func saveRoute() {
        // Seçili çalışanları al
        let selectedEmployeeIds = employeeViewModel.getSelectedEmployeeIds()
        
        // Route nesnesini güncelle
        viewModel.formVal.assignedDate = ISO8601DateFormatter().string(from: selectedDate)
        viewModel.formVal.shareWithEmployees = shareWithEmployees
        viewModel.formVal.sharedEmployeeIds = selectedEmployeeIds
        
        SessionManager.shared.isLoading = true
        viewModel.createRoute(route: viewModel.formVal) { result in
            SessionManager.shared.isLoading = false
            switch result {
            case .success:
                // Yeni rota eklendiyse, rotaları tekrar yükle
                viewModel.loadRoutes()
                createdRoute = viewModel.formVal
                showSuccessView = true
                // Callback'i çağır
                onRouteCreated?()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        
        /*
        viewModel.createRoute(route: viewModel.formVal) { result in
            switch result {
            case .success:
                await MainActor.run { dismiss() }
            case .failure(let error):
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
         */
    }
}

#Preview {
    NewRouteSheet()
} 

// MARK: - Helper Functions
extension NewRouteSheet {
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
} 
