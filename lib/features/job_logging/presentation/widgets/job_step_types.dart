import 'package:flutter/material.dart';
import '../../../inventory/domain/entities/inventory_item_entity.dart';

/// Row types used across the Add New Job wizard steps.
/// These were previously private to log_job_screen.dart.

class ServiceRow {
  String? serviceType;
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController();

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}

class ItemRow {
  String? inventoryItemId;
  InventoryItemEntity? inventoryItem;
  final nameController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController();

  bool get isFromInventory => inventoryItem != null;
  String get displayName => isFromInventory ? inventoryItem!.name : nameController.text.trim();
  String get displayPrice => priceController.text.trim();

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }

  ItemRow copy() {
    final i = ItemRow();
    i.inventoryItemId = inventoryItemId;
    i.inventoryItem = inventoryItem;
    i.nameController.text = nameController.text;
    i.qtyController.text = qtyController.text;
    i.priceController.text = priceController.text;
    return i;
  }
}

class PartRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  String? inventoryItemId;

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
  }

  PartRow copy() {
    final p = PartRow();
    p.nameController.text = nameController.text;
    p.qtyController.text = qtyController.text;
    p.inventoryItemId = inventoryItemId;
    return p;
  }
}

class HardwareRow {
  String? domain;
  String? category;
  final nameController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  String? inventoryItemId;
  InventoryItemEntity? inventoryItem;

  bool get isFromInventory => inventoryItem != null;
  String get displayName => isFromInventory ? inventoryItem!.name : nameController.text.trim();

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
  }

  HardwareRow copy() {
    final h = HardwareRow();
    h.domain = domain;
    h.category = category;
    h.inventoryItemId = inventoryItemId;
    h.inventoryItem = inventoryItem;
    h.nameController.text = nameController.text;
    h.qtyController.text = qtyController.text;
    return h;
  }
}

class ExpenseRow {
  String category = 'transport';
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
  }

  ExpenseRow copy() {
    final e = ExpenseRow();
    e.category = category;
    e.descriptionController.text = descriptionController.text;
    e.amountController.text = amountController.text;
    return e;
  }
}
