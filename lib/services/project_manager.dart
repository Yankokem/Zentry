import 'package:zentry/models/project_model.dart';
import 'package:zentry/models/ticket_model.dart';

class ProjectManager {
  static final ProjectManager _instance = ProjectManager._internal();
  factory ProjectManager() => _instance;
  ProjectManager._internal();

  // Sample Projects
  final List<Project> _projects = [
    Project(
      id: 'proj_001',
      title: 'Mobile App Development',
      description: 'Building the next-generation mobile application with Flutter',
      teamMembers: ['John Doe', 'Sarah Lee', 'Mike Chen', 'Anna Smith'],
      status: 'In Progress',
      totalTickets: 24,
      completedTickets: 12,
      color: 'yellow',
    ),
    Project(
      id: 'proj_002',
      title: 'Website Redesign',
      description: 'Complete overhaul of company website with modern UI/UX',
      teamMembers: ['Sarah Lee', 'Tom Wilson'],
      status: 'In Progress',
      totalTickets: 18,
      completedTickets: 8,
      color: 'blue',
    ),
    Project(
      id: 'proj_003',
      title: 'API Integration',
      description: 'Integrate third-party APIs for payment and analytics',
      teamMembers: ['John Doe', 'Mike Chen'],
      status: 'Planning',
      totalTickets: 15,
      completedTickets: 2,
      color: 'green',
    ),
    Project(
      id: 'proj_004',
      title: 'Database Migration',
      description: 'Migrate from SQL to NoSQL database for better scalability',
      teamMembers: ['Mike Chen', 'Anna Smith', 'John Doe'],
      status: 'In Progress',
      totalTickets: 20,
      completedTickets: 15,
      color: 'purple',
    ),
    Project(
      id: 'proj_005',
      title: 'Security Audit',
      description: 'Comprehensive security review and implementation of fixes',
      teamMembers: ['Anna Smith', 'Tom Wilson'],
      status: 'Completed',
      totalTickets: 10,
      completedTickets: 10,
      color: 'red',
    ),
  ];

  // Sample Tickets
  final List<Ticket> _tickets = [
    // Mobile App Development Tickets
    Ticket(
      ticketNumber: 'TICK-001',
      title: 'Design login screen',
      description: 'Create modern login UI with social auth options',
      priority: 'high',
      status: 'done',
      assignedTo: 'Sarah Lee',
      projectId: 'proj_001',
    ),
    Ticket(
      ticketNumber: 'TICK-002',
      title: 'Implement authentication',
      description: 'Set up Firebase authentication with email and Google',
      priority: 'high',
      status: 'in_progress',
      assignedTo: 'John Doe',
      projectId: 'proj_001',
    ),
    Ticket(
      ticketNumber: 'TICK-003',
      title: 'Create user profile page',
      description: 'User can view and edit their profile information',
      priority: 'medium',
      status: 'in_review',
      assignedTo: 'Mike Chen',
      projectId: 'proj_001',
    ),
    Ticket(
      ticketNumber: 'TICK-004',
      title: 'Add push notifications',
      description: 'Implement FCM for push notifications',
      priority: 'medium',
      status: 'todo',
      assignedTo: 'Anna Smith',
      projectId: 'proj_001',
    ),
    Ticket(
      ticketNumber: 'TICK-005',
      title: 'Setup CI/CD pipeline',
      description: 'Configure automated testing and deployment',
      priority: 'low',
      status: 'todo',
      assignedTo: 'John Doe',
      projectId: 'proj_001',
    ),
    Ticket(
      ticketNumber: 'TICK-006',
      title: 'Dark mode support',
      description: 'Add dark theme throughout the app',
      priority: 'low',
      status: 'in_progress',
      assignedTo: 'Sarah Lee',
      projectId: 'proj_001',
    ),

    // Website Redesign Tickets
    Ticket(
      ticketNumber: 'TICK-007',
      title: 'Homepage mockup',
      description: 'Design new homepage layout in Figma',
      priority: 'high',
      status: 'done',
      assignedTo: 'Sarah Lee',
      projectId: 'proj_002',
    ),
    Ticket(
      ticketNumber: 'TICK-008',
      title: 'Responsive navigation',
      description: 'Create mobile-friendly navigation menu',
      priority: 'high',
      status: 'in_progress',
      assignedTo: 'Tom Wilson',
      projectId: 'proj_002',
    ),
    Ticket(
      ticketNumber: 'TICK-009',
      title: 'Contact form',
      description: 'Build contact form with validation',
      priority: 'medium',
      status: 'todo',
      assignedTo: 'Sarah Lee',
      projectId: 'proj_002',
    ),

    // API Integration Tickets
    Ticket(
      ticketNumber: 'TICK-010',
      title: 'Stripe payment setup',
      description: 'Integrate Stripe payment gateway',
      priority: 'high',
      status: 'in_progress',
      assignedTo: 'John Doe',
      projectId: 'proj_003',
    ),
    Ticket(
      ticketNumber: 'TICK-011',
      title: 'Analytics dashboard',
      description: 'Connect Google Analytics API',
      priority: 'medium',
      status: 'todo',
      assignedTo: 'Mike Chen',
      projectId: 'proj_003',
    ),

    // Database Migration Tickets
    Ticket(
      ticketNumber: 'TICK-012',
      title: 'Schema design',
      description: 'Design MongoDB schema structure',
      priority: 'high',
      status: 'done',
      assignedTo: 'Mike Chen',
      projectId: 'proj_004',
    ),
    Ticket(
      ticketNumber: 'TICK-013',
      title: 'Data migration script',
      description: 'Write scripts to migrate existing data',
      priority: 'high',
      status: 'in_review',
      assignedTo: 'Anna Smith',
      projectId: 'proj_004',
    ),
    Ticket(
      ticketNumber: 'TICK-014',
      title: 'Performance testing',
      description: 'Test query performance on new database',
      priority: 'medium',
      status: 'in_progress',
      assignedTo: 'John Doe',
      projectId: 'proj_004',
    ),

    // Security Audit Tickets
    Ticket(
      ticketNumber: 'TICK-015',
      title: 'SQL injection fixes',
      description: 'Patch all SQL injection vulnerabilities',
      priority: 'high',
      status: 'done',
      assignedTo: 'Anna Smith',
      projectId: 'proj_005',
    ),
    Ticket(
      ticketNumber: 'TICK-016',
      title: 'Update dependencies',
      description: 'Update all packages to latest secure versions',
      priority: 'high',
      status: 'done',
      assignedTo: 'Tom Wilson',
      projectId: 'proj_005',
    ),
  ];

  List<Project> get projects => _projects;
  List<Ticket> get tickets => _tickets;

  List<Ticket> getTicketsByProject(String projectId) {
    return _tickets.where((ticket) => ticket.projectId == projectId).toList();
  }

  List<Ticket> getTicketsByStatus(String projectId, String status) {
    return _tickets
        .where((ticket) => 
            ticket.projectId == projectId && ticket.status == status)
        .toList();
  }

  void addProject(Project project) {
    _projects.add(project);
  }

  void addTicket(Ticket ticket) {
    _tickets.add(ticket);
  }

  void updateTicket(String ticketNumber, Ticket updatedTicket) {
    final index = _tickets.indexWhere((t) => t.ticketNumber == ticketNumber);
    if (index != -1) {
      _tickets[index] = updatedTicket;
    }
  }

  void deleteTicket(String ticketNumber) {
    _tickets.removeWhere((t) => t.ticketNumber == ticketNumber);
  }
}