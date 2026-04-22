import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/screens/edit_address_screen.dart';
import 'package:krishikranti/screens/payment_screen.dart';
import 'package:krishikranti/core/profile_service.dart';

class AddressModel {
  String id;
  String name;
  String address;
  String phone;
  bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.isDefault = false,
  });
}

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  List<AddressModel> addresses = [];
  String? selectedAddressId;

  @override
  void initState() {
    super.initState();
    _loadProfileAddress();
  }

  void _loadProfileAddress() {
    final profile = Provider.of<ProfileService>(context, listen: false);
    if (profile.name.isNotEmpty && profile.address1.isNotEmpty) {
      final fullAddress = "${profile.address1}, ${profile.address2.isNotEmpty ? "${profile.address2}, " : ""}${profile.city}, ${profile.state} - ${profile.pincode}";
      
      final profileAddr = AddressModel(
        id: "profile_default",
        name: profile.name,
        address: fullAddress,
        phone: profile.phone,
        isDefault: true,
      );
      
      setState(() {
        addresses = [profileAddr];
        selectedAddressId = profileAddr.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.shippingAddress,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Add Address Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditAddressScreen(),
                      ),
                    );
                    if (result != null && result is AddressModel) {
                      setState(() {
                        addresses.add(result);
                        selectedAddressId ??= result.id;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.plus_circle_fill, size: 16, color: primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          l10n.addAddress,
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Address List
          Expanded(
            child: addresses.isEmpty 
            ? _buildEmptyState()
            : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final address = addresses[index];
                final isSelected = selectedAddressId == address.id;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAddressId = address.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? primaryGreen : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Radio Selection
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            isSelected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                            color: isSelected ? primaryGreen : Colors.grey.shade400,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Address Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    address.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (address.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l10n.defaultLabel,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                address.address,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                address.phone,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _actionBtn(
                                    CupertinoIcons.pencil,
                                    l10n.edit,
                                    () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditAddressScreen(address: address),
                                        ),
                                      );
                                      if (result != null && result is AddressModel) {
                                        setState(() {
                                          addresses[index] = result;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 20),
                                  _actionBtn(
                                    CupertinoIcons.trash,
                                    l10n.delete,
                                    () {
                                      setState(() {
                                        addresses.removeAt(index);
                                        if (selectedAddressId == address.id) {
                                          selectedAddressId = addresses.isNotEmpty ? addresses.first.id : null;
                                        }
                                      });
                                    },
                                    color: Colors.red.shade400,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: addresses.isEmpty ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              l10n.deliverHere,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.location_slash, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            l10n.noAddressesFound,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addAddressToContinue,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
