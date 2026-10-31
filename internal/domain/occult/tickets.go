package occult

// AccrueTickets turns spent energy into tickets. Progress carries the energy
// remainder; at the cap the remainder is dropped so a full holder earns nothing.
func AccrueTickets(tickets, progress, spent int64) (int64, int64) {
	if spent <= 0 || tickets >= TicketCap {
		return min(tickets, TicketCap), 0
	}
	total := progress + spent
	tickets = min(tickets+total/EnergyPerTicket, TicketCap)
	if tickets >= TicketCap {
		return tickets, 0
	}
	return tickets, total % EnergyPerTicket
}
